import json
from pathlib import Path

from clinic.presentation.api import app

Path("../shared_contracts/openapi.json").write_text(
    json.dumps(app.openapi(), indent=2) + "\n", encoding="utf-8"
)
