import re

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'r') as f:
    content = f.read()

# 1. Add upload state
old_state = "const [isSaving, setIsSaving] = useState(false);"
new_state = "const [isSaving, setIsSaving] = useState(false);\n  const [isUploading, setIsUploading] = useState(false);\n  const fileInputRef = useRef<HTMLInputElement>(null);"
content = content.replace(old_state, new_state)

# Add useRef import if missing
if "useRef" not in content:
    content = content.replace("useState", "useState, useRef")

# 2. Add handleFileUpload function
upload_func = """
  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsUploading(true);
    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await fetch("/api/questions/import", {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      if (res.ok) {
        alert(`${data.count} questions importees avec succes !`);
        fetchQuestions();
      } else {
        alert(`Erreur: ${data.error}`);
      }
    } catch (err) {
      alert("Erreur reseau lors de l'import.");
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };
"""

content = content.replace("const handleSave = async (e: React.FormEvent) => {", upload_func + "\n  const handleSave = async (e: React.FormEvent) => {")

# 3. Add button in UI
old_btn = """          <button onClick={() => setFormMode("add")} className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-semibold">
            + Ajouter une question
          </button>"""
new_btn = """          <div className="flex gap-2">
            <input 
              type="file" 
              accept=".md" 
              className="hidden" 
              ref={fileInputRef} 
              onChange={handleFileUpload} 
            />
            <button 
              onClick={() => fileInputRef.current?.click()} 
              disabled={isUploading}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded text-sm font-semibold flex items-center gap-2"
            >
              {isUploading ? "Importation..." : "Importer un fichier .md"}
            </button>
            <button onClick={() => setFormMode("add")} className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-semibold">
              + Ajouter
            </button>
          </div>"""
content = content.replace(old_btn, new_btn)

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'w') as f:
    f.write(content)
