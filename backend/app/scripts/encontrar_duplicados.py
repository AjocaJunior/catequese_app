"""
Localiza catequisandos e catequistas com nomes duplicados (mesmo nome,
ignorando maiúsculas/espaços) — útil depois de atualizar para a versão com
verificação de nome único, já que dados antigos podem ter duplicados que
precisam de resolução manual (decidir qual registo manter, e o que fazer
às presenças/transações já associadas ao que for removido).

Este script só LÊ e reporta — não apaga nem altera nada.

Uso:
    pip install requests
    python scripts/encontrar_duplicados.py
"""
import os
from collections import defaultdict

import requests

API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000")
ADMIN_EMAIL = os.environ.get("ADMIN_EMAIL") or input("Email do administrador: ")
ADMIN_PASSWORD = os.environ.get("ADMIN_PASSWORD") or input("Palavra-passe: ")


def _normalizar(nome: str) -> str:
    return " ".join(nome.strip().lower().split())


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

    # --- Catequisandos ---
    catequisandos = requests.get(f"{API_BASE_URL}/catequisandos", headers=headers).json()
    por_nome = defaultdict(list)
    for c in catequisandos:
        por_nome[_normalizar(c["nome"])].append(c)

    duplicados = {nome: lista for nome, lista in por_nome.items() if len(lista) > 1}
    if duplicados:
        print(f"⚠ {len(duplicados)} nome(s) de CATEQUISANDO duplicado(s):\n")
        for nome, lista in duplicados.items():
            print(f"  '{lista[0]['nome']}':")
            for c in lista:
                print(f"    - id={c['id']} | fase={c['fase_nome']} | criado_em={c['criado_em']}")
        print()
    else:
        print("✅ Nenhum nome de catequisando duplicado.\n")

    # --- Catequistas ---
    catequistas = requests.get(f"{API_BASE_URL}/catequistas", headers=headers).json()
    por_nome_cat = defaultdict(list)
    for c in catequistas:
        por_nome_cat[_normalizar(c["nome"])].append(c)

    duplicados_cat = {nome: lista for nome, lista in por_nome_cat.items() if len(lista) > 1}
    if duplicados_cat:
        print(f"⚠ {len(duplicados_cat)} nome(s) de CATEQUISTA duplicado(s):\n")
        for nome, lista in duplicados_cat.items():
            print(f"  '{lista[0]['nome']}':")
            for c in lista:
                print(f"    - id={c['id']} | email={c['email']} | admin={c['is_admin']}")
        print()
    else:
        print("✅ Nenhum nome de catequista duplicado.\n")

    if duplicados or duplicados_cat:
        print(
            "Resolve manualmente na app (editar/apagar o registo a menos) antes de correres\n"
            "novamente o backend — enquanto houver duplicados, o índice único não é criado\n"
            "e novos duplicados continuam bloqueados só ao nível da aplicação."
        )


if __name__ == "__main__":
    main()
