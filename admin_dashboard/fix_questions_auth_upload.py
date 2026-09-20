import re

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'r') as f:
    content = f.read()

# 1. Add auth state
if "const [user" not in content:
    content = content.replace(
        "const [questions, setQuestions] = useState<Question[]>([]);",
        "const [user, setUser] = useState<any>(null);\n  const [questions, setQuestions] = useState<Question[]>([]);"
    )

# 2. Add auth check in useEffect
old_use_effect = """  useEffect(() => {
    chargerQuestions();
  }, []);"""
new_use_effect = """  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      if (!data.user) {
        window.location.href = "/";
      } else {
        setUser(data.user);
        chargerQuestions();
      }
    });
  }, []);"""
if "window.location.href = \"/\";" not in content:
    content = content.replace(old_use_effect, new_use_effect)

# 3. Add handleFileUpload function
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
        chargerQuestions();
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
    content = content.replace("  const chargerQuestions = async () => {", upload_func + "\n  const chargerQuestions = async () => {")

# 4. Replace the header buttons
old_header_btn = """        <button
          onClick={() => { setShowForm(true); setEditQuestion(null); }}
          className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-bold"
        >
          + AJOUTER
        </button>"""
new_header_btn = """        <div className="flex gap-2">
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
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded text-sm font-bold flex items-center gap-2"
          >
            {isUploading ? "IMPORTATION..." : "IMPORTER MD"}
          </button>
          <button
            onClick={() => { setShowForm(true); setEditQuestion(null); }}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded text-sm font-bold"
          >
            + AJOUTER
          </button>
        </div>"""
if "IMPORTER MD" not in content:
    content = content.replace(old_header_btn, new_header_btn)

with open('/mnt/c/All-projects/2026/Otaku_verse/admin_dashboard/app/questions/page.tsx', 'w') as f:
    f.write(content)
