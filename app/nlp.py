import spacy

# Load small English model
nlp = spacy.load("en_core_web_sm")

def extract_named_entities(text: str):
    doc = nlp(text)
    
    # Format entities as a list of dictionaries for clean JSON responses
    return [{"text": ent.text, "label": ent.label_} for ent in doc.ents]
