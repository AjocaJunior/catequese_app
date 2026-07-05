"""
Popula os ministérios e sectores reais da paróquia, via API.

É seguro correr mais do que uma vez: verifica o que já existe (por nome)
e só cria o que falta.

Uso:
    pip install requests
    python scripts/seed_ministerios.py

Por omissão liga a http://localhost:8000. Para apontar ao Render:
    API_BASE_URL=https://o-teu-servico.onrender.com python scripts/seed_ministerios.py

Pede o email/password de um administrador (ou define ADMIN_EMAIL / ADMIN_PASSWORD
como variáveis de ambiente para correr sem interação).
"""
import os

import requests

API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL") or input("Email do administrador: ")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD") or input("Palavra-passe: ")

# Estrutura real da paróquia. Ministérios 6, 7 e 8 não têm sectores listados
# (fica como lista vazia — aparecem no organograma só com o nome do ministério).
ESTRUTURA: dict[str, list[str]] = {
    "Ministério da Pastoral Social": [
        "Caridade",
        "Justiça e Paz",
        "Migrantes",
        "Educação",
        "Saúde",
        "Mulher",
        "Comunicação Social",
        "Desenvolvimento",
    ],
    "Ministério da Liturgia": [
        "Formação",
        "Cantos e Instrumentos",
        "Acolhimento",
        "Sacristia",
        "Acólitos",
        "Serviço Extraordinário da Comunhão",
        "Serviço da Esperança",
    ],
    "Ministério da Catequese e Formação Permanente": [
        "Formação catequética e acompanhamento dos Catequistas",
        "Formação Bíblica",
        "Formação humana, cristã e sócio-política para os membros da comunidade cristã",
    ],
    "Ministério da Família": [
        "Casais",
        "Jovens",
        "Adolescentes e Crianças",
        "Vocações",
        "Terceira Idade",
    ],
    "Ministério da Administração": [
        "Finanças",
        "Património",
        "Dízimo",
    ],
    "Ministério do Ecumenismo e do Diálogo Inter-Religioso": [],
    "Ministério da Animação da Comunidade": [],
    "Ministério da Animação dos Núcleos": [],
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

    ministerios_existentes = {
        m["nome"]: m["id"]
        for m in requests.get(f"{API_BASE_URL}/ministerios", headers=headers).json()
    }
    sectores_existentes = {
        s["nome"] for s in requests.get(f"{API_BASE_URL}/sectores", headers=headers).json()
    }

    criados_ministerios = 0
    criados_sectores = 0

    for nome_ministerio, sectores in ESTRUTURA.items():
        if nome_ministerio in ministerios_existentes:
            ministerio_id = ministerios_existentes[nome_ministerio]
            print(f"= Ministério já existe: {nome_ministerio}")
        else:
            resp = requests.post(f"{API_BASE_URL}/ministerios", json={"nome": nome_ministerio}, headers=headers)
            if resp.status_code >= 400:
                print(f"! Erro ao criar ministério '{nome_ministerio}': {resp.status_code} {resp.text}")
                continue
            ministerio_id = resp.json()["id"]
            criados_ministerios += 1
            print(f"+ Ministério criado: {nome_ministerio}")

        for nome_sector in sectores:
            if nome_sector in sectores_existentes:
                print(f"  = Sector já existe: {nome_sector}")
                continue
            resp = requests.post(
                f"{API_BASE_URL}/sectores",
                json={"nome": nome_sector, "ministerio_id": ministerio_id},
                headers=headers,
            )
            if resp.status_code >= 400:
                print(f"  ! Erro ao criar sector '{nome_sector}': {resp.status_code} {resp.text}")
                continue
            criados_sectores += 1
            sectores_existentes.add(nome_sector)
            print(f"  + Sector criado: {nome_sector}")

    print(f"\nConcluído: {criados_ministerios} ministério(s) novo(s), {criados_sectores} sector(es) novo(s).")
    print("Os dias/horas e responsáveis dos sectores ficam por preencher — edita-os na app quando tiveres essa informação.")


if __name__ == "__main__":
    main()
