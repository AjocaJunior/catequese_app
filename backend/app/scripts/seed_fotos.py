"""
Envia as fotos da pasta fotos_iniciais/ para o carrossel público, via API.
É seguro correr mais do que uma vez: verifica pelos títulos já existentes.

Uso:
    pip install requests
    python scripts/seed_fotos.py

Por omissão liga a http://localhost:8000. Para apontar ao Render:
    API_BASE_URL=https://o-teu-servico.onrender.com python scripts/seed_fotos.py
"""
import os
from pathlib import Path

import requests

API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL") or input("Email do administrador: ")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD") or input("Palavra-passe: ")

PASTA_FOTOS = Path(__file__).parent / "fotos_iniciais"

# Nome do ficheiro -> título a mostrar no carrossel
FOTOS = {
    "ordenacao_dos_responsaveis.jpg": "Ordenação dos Responsáveis",
    "despedida_de_padre_romao.jpg": "Despedida do Padre Romão",
    "festa_da_crianca_2026.jpg": "Festa da Criança 2026",
}


def login() -> str:
    resp = requests.post(
        f"{API_BASE_URL}/auth/login",
        data={"username": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
    )
    resp.raise_for_status()
    return resp.json()["access_token"]


def main() -> None:
    print(f"A ligar a {API_BASE_URL}...")
    token = login()
    headers = {"Authorization": f"Bearer {token}"}
    print("Login OK.\n")

    titulos_existentes = {f["titulo"] for f in requests.get(f"{API_BASE_URL}/fotos", headers=headers).json()}

    enviadas = 0
    for nome_ficheiro, titulo in FOTOS.items():
        if titulo in titulos_existentes:
            print(f"= Já existe: {titulo}")
            continue

        caminho = PASTA_FOTOS / nome_ficheiro
        if not caminho.exists():
            print(f"! Ficheiro não encontrado: {caminho}")
            continue

        with open(caminho, "rb") as f:
            resp = requests.post(
                f"{API_BASE_URL}/fotos",
                data={"titulo": titulo},
                files={"imagem": (nome_ficheiro, f, "image/jpeg")},
                headers=headers,
            )
        if resp.status_code >= 400:
            print(f"! Erro ao enviar '{titulo}': {resp.status_code} {resp.text}")
            continue

        enviadas += 1
        print(f"+ Enviada: {titulo}")

    print(f"\nConcluído: {enviadas} foto(s) nova(s) enviada(s).")


if __name__ == "__main__":
    main()
