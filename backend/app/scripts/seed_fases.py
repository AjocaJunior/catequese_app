"""
Popula as fases reais da Comunidade Santa Ana - Mastrong (dia, hora, local),
a partir da planilha "CATEQUISTAS - SANTA ANA 2026".

É seguro correr mais do que uma vez: verifica pelo nome já existente e só
cria o que falta. NÃO cria catequistas (isso requer email/password próprios
de cada pessoa) — só as fases, prontas para quando cada catequista se
registar e for atribuído pelo administrador.

Uso:
    pip install requests
    python scripts/seed_fases.py
"""
import os

import requests

API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL") or input("Email do administrador: ")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD") or input("Palavra-passe: ")

# nome -> (dia_semana, hora, local)
# Nota: a "3ª Fase" aparece na planilha original com 2 salas diferentes
# (Sala 2 para um catequista, Sala 3 para outros dois) — assumi "Sala 3"
# por ser a maioria; ajusta na app se não for o que pretendes.
FASES = {
    "1ª Fase": ("sabado", "08H30", "Salão"),
    "2ª Fase": ("sabado", "08H30", "Sala 2"),
    "3ª Fase": ("sabado", "08H30", "Sala 3"),
    "4ª Fase": ("sabado", "08H30", "Sala 4"),
    "1º Ano de Aprofundamento": ("sabado", "08H30", "Amendoeira"),
    "Pré-Catecumenato": ("sabado", "14H30", "Sala 2"),
    "1º Ano de Catecumenato": ("sabado", "14H30", "Sala 3"),
    "2º Ano de Catecumenato": ("sabado", "14H30", "Sala 4"),
    "1º Ano de Crisma": ("sabado", "14H30", "Amendoeira"),
    "2º Ano de Crisma": ("sabado", "14H30", "Mangueira"),
    "3º Ano de Crisma": ("sabado", "14H30", "Portão"),
    "Adultos": ("domingo", "18H30", "Salão"),
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

    existentes = {f["nome"] for f in requests.get(f"{API_BASE_URL}/fases", headers=headers).json()}

    criadas = 0
    for nome, (dia_semana, hora, local) in FASES.items():
        if nome in existentes:
            print(f"= Já existe: {nome}")
            continue

        resp = requests.post(
            f"{API_BASE_URL}/fases",
            json={"nome": nome, "dia_semana": dia_semana, "hora": hora, "local": local},
            headers=headers,
        )
        if resp.status_code >= 400:
            print(f"! Erro ao criar '{nome}': {resp.status_code} {resp.text}")
            continue

        criadas += 1
        print(f"+ Criada: {nome} ({dia_semana}, {hora}, {local})")

    print(f"\nConcluído: {criadas} fase(s) nova(s) criada(s).")
    print(
        "Os catequistas ainda não foram criados (precisam de se registar com o seu próprio email).\n"
        "Depois de cada um se registar, atribui-os à fase certa em 'Fases catequéticas' na app,\n"
        "e pede-lhes para preencherem o contacto no perfil deles."
    )


if __name__ == "__main__":
    main()
