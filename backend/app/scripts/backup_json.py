"""
Script de backup manual: exporta todas as coleções da base de dados para
ficheiros JSON, e comprime tudo num único .zip com a data no nome.

Uso (a partir da pasta backend/, com o .venv ativo):
    python scripts/backup_json.py

Usa a mesma MONGODB_URI/DB_NAME já configurada no teu .env — não precisas
de escrever a password em lado nenhum.
"""
import json
import sys
import zipfile
from datetime import date, datetime
from pathlib import Path

from bson import ObjectId
from pymongo import MongoClient

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from app.core.config import get_settings  # noqa: E402


class CodificadorMongo(json.JSONEncoder):
    """Converte tipos do MongoDB (ObjectId, datetime) para texto, para
    poderem ser guardados em JSON normal."""

    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()
        return super().default(obj)


def main() -> None:
    settings = get_settings()
    cliente = MongoClient(settings.MONGODB_URI)
    db = cliente[settings.DB_NAME]

    agora = datetime.now().strftime("%Y-%m-%d_%Hh%M")
    pasta_saida = Path(__file__).resolve().parent / f"backup_{agora}"
    pasta_saida.mkdir(exist_ok=True)

    colecoes = db.list_collection_names()
    print(f"A exportar {len(colecoes)} coleções de '{settings.DB_NAME}'...")

    for nome_colecao in colecoes:
        documentos = list(db[nome_colecao].find({}))
        caminho = pasta_saida / f"{nome_colecao}.json"
        with open(caminho, "w", encoding="utf-8") as f:
            json.dump(documentos, f, cls=CodificadorMongo, ensure_ascii=False, indent=2)
        print(f"  {nome_colecao}: {len(documentos)} documentos")

    caminho_zip = f"{pasta_saida}.zip"
    with zipfile.ZipFile(caminho_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for ficheiro in pasta_saida.iterdir():
            zf.write(ficheiro, ficheiro.name)

    for ficheiro in pasta_saida.iterdir():
        ficheiro.unlink()
    pasta_saida.rmdir()

    print(f"\nBackup concluído: {caminho_zip}")
    print("Guarda este ficheiro num sítio seguro (Google Drive, OneDrive, disco externo) e depois apaga-o daqui.")


if __name__ == "__main__":
    main()
