import re

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'r') as f:
    content = f.read()

# 1. Inject state
old_state = "const [editQuestion, setEditQuestion] = useState<Question | null>(null);"
new_state = "const [editQuestion, setEditQuestion] = useState<Question | null>(null);\n  const [isUploading, setIsUploading] = useState(false);\n  const fileInputRef = useRef<HTMLInputElement>(null);"

if "const [isUploading" not in content:
    content = content.replace(old_state, new_state)

# 2. Add handleFileUpload function before handleSave
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

if "handleFileUpload" not in content:
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
            <button onClick={() => {
              setEditQuestion(null);
              setForm({ anime: "", arc: "", difficulte: "moyen", question: "", choix_a: "", choix_b: "", choix_c: "", choix_d: "", bonne_reponse: "A", explication: "" });
              setShowForm(true);
            }} className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-semibold">
              + Ajouter une question
            </button>
          </div>"""

if "Importer un fichier .md" not in content:
    content = content.replace(old_btn, new_btn)

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'w') as f:
    f.write(content)
