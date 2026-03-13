# Templates DOCX

Le moteur MVP attend un gabarit `.docx` avec des tokens texte, par exemple:

- `{{document.titre_long}}`
- `{{document.code_document}}`
- `{{acteurs.service_responsable}}`
- `{{BODY_BLOCKS}}` (insertion de blocs structurés)

Les styles Word nommés doivent exister dans le gabarit (ex: `Titre_Niveau_1`, `Corps_Texte`, etc.).
