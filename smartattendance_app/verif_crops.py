from PIL import Image

im = Image.open('C:/Users/emman/.gemini/antigravity/brain/6143fcdd-bbc3-4369-8a1d-afe9888ebb4e/artemis_101_preview_real.png')

# 1. Summary row (Registros, Empleados, Entradas, Salidas)
summary = im.crop((50, 1040, 1030, 1280))
summary.save('C:/Users/emman/Downloads/Capturas_SmartAttendance/verif_1_summary.png')

# 2. Table header and first 3 rows
table = im.crop((50, 1420, 1030, 1750))
table.save('C:/Users/emman/Downloads/Capturas_SmartAttendance/verif_2_table_rows.png')

# 3. Action buttons
actions = im.crop((50, 2220, 1030, 2370))
actions.save('C:/Users/emman/Downloads/Capturas_SmartAttendance/verif_3_actions.png')

print('Verification crops saved!')
