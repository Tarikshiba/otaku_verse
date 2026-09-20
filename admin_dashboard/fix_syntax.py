import re

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'r') as f:
    content = f.read()

# Fix the broken hooks
content = content.replace("useState, useRef<", "useState<")
content = content.replace("useState, useRef(", "useState(")
content = content.replace("useState, useRef", "useState")

# Fix the imports if we accidentally removed useRef
if "import { useState, useRef, useEffect }" not in content:
    content = content.replace('import { useState, useEffect }', 'import { useState, useRef, useEffect }')
    content = content.replace('import { useState }', 'import { useState, useRef }')
    
# Wait, let's just make sure the imports line is correct:
content = content.replace('import { useState } from "react";', 'import { useState, useRef, useEffect } from "react";')
content = content.replace('import { useState, useEffect } from "react";', 'import { useState, useRef, useEffect } from "react";')

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'w') as f:
    f.write(content)
