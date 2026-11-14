"""Prueba la política de claims ya verificados, sin simular el servicio Google."""
import pytest
from fastapi import HTTPException
from app.services.google_identity_policy import account_email


@pytest.mark.parametrize('claims', [
    {'email': 'qa@gmail.com', 'email_verified': False, 'sub': 'qa'},
    {'email': 'qa@gmail.com', 'sub': 'qa'},
    {'email': 'qa@example.org', 'email_verified': True, 'sub': 'qa'},
    {'email': 'qa@example.org', 'email_verified': True, 'sub': 'qa', 'hd': 'other.org'},
    {'email': 'qa@gmail.com', 'email_verified': True},
])
def test_untrusted_email_cannot_select_a_local_account(claims):
    with pytest.raises(HTTPException) as error:
        account_email(claims)
    assert error.value.status_code == 401


@pytest.mark.parametrize('email,hosted_domain', [('qa@gmail.com', None), ('qa@example.org', 'example.org')])
def test_verified_authoritative_email_can_be_used(email, hosted_domain):
    assert account_email({'email': email, 'sub': 'qa', 'email_verified': True,
                          'hd': hosted_domain}) == email
