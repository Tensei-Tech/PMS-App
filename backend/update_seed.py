import re

with open('apps/crimetab/management/commands/seed_common_form.py', 'r') as f:
    content = f.read()

# Replace the specific 'Registration Date' field
content = content.replace(
    "('Registration Date & Time', 'registered_datetime', 'common', 'datetime', True, 20),",
    "('Registered Date (dd/mm/yyyy)', 'registered_datetime', 'common', 'date', True, 20),"
)

# We need to add a 7th element to the tuples which is the section name.
# It can be inferred from the comments.
lines = content.split('\n')
new_lines = []
current_section = 'Crime Registration Info'
for line in lines:
    if line.strip().startswith('# ') and line.strip()[2].isdigit():
        # e.g., # 1. Registration Info
        parts = line.strip().split('.', 1)
        if len(parts) > 1:
            sec_name = parts[1].strip()
            # Map comments to the exact keys used in dynamic_form_screen.dart
            mapping = {
                'Registration Info': 'Crime Registration Info',
                'Crime Spot': 'Crime Spot',
                'Acts & Sections (Charges)': 'Acts & Sections Filed',
                'Complainant KYC': 'Complainant',
                'Accused KYC': 'Accused',
                'Unidentified Accused': 'Unidentified Accused',
                'Responsibility': 'Officer',
                'Arrest & Release Status': 'Arrest',
                'Remand & Custody': 'Remand & Custody',
                'CCTV & Technical': 'CCTV and CDR Investigation',
                'Procedural Checklist': 'All Panchnama',
                'Forensics': 'Evidence',
                'Seizures': 'Seizure Records',
                'Preventive Action Items': 'Preventive Action',
                'Preventive Bond': 'Bond',
                'Discharge Status': 'Discharge Accused',
                'Scrutiny Pipeline': 'Scrutiny',
                'Final Verdict': 'Court Filing and Final Summary',
            }
            if sec_name in mapping:
                current_section = mapping[sec_name]
            else:
                current_section = sec_name
    
    # Check if the line contains a field tuple
    match = re.search(r"^\s*\(\s*'.+?',\s*'.+?',\s*'.+?',\s*'.+?',\s*(True|False),\s*\d+\s*\)\s*,\s*$", line)
    if match:
        # It's a field tuple, append the current_section
        # But wait, Unknown Accused Involved is under # 1. Registration Info
        # We should move it to Unidentified Accused
        if 'is_unknown_accused' in line:
            line = line.replace('),', f", 'Unidentified Accused'),")
        else:
            line = line.replace('),', f", '{current_section}'),")
    
    new_lines.append(line)

content = '\n'.join(new_lines)

# Update the unpacking in the for loop
content = content.replace(
    'for label, key, src, ftype, req, order in common_fields:',
    'for label, key, src, ftype, req, order, section in common_fields:'
)

content = content.replace(
    'display_order=order,',
    'display_order=order,\n                section=section,'
)

with open('apps/crimetab/management/commands/seed_common_form.py', 'w') as f:
    f.write(content)
print('Script finished')
