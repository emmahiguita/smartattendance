from PIL import Image

im = Image.open('artemis_btn.png')
# Save full view to Downloads
im.save('C:/Users/emman/Downloads/Capturas_SmartAttendance/artemis_104_modal_scrolled_full.png')

# Slice 1: y=1200 to 1800
im.crop((40, 1200, 1040, 1800)).save('C:/Users/emman/Downloads/Capturas_SmartAttendance/artemis_105_table_region.png')
# Slice 2: y=1800 to 2400
im.crop((40, 1800, 1040, 2400)).save('C:/Users/emman/Downloads/Capturas_SmartAttendance/artemis_106_actions_region.png')
print('Saved slices 104, 105, 106!')
