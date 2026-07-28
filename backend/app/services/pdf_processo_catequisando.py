import io
from datetime import date, datetime

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.core.liturgico import esta_em_quaresma
from app.services.pdf_comum import (
    COR_AZUL_ESCURO,
    COR_LINHA_ALTERNADA,
    bloco_assinatura,
    bloco_cabecalho,
    estilos_documento,
)

_ROTULO_GENERO = {"masculino": "Masculino", "feminino": "Feminino"}
_MESES = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
]
_MARCA_STATUS = {"presente": "P", "falta": "F", "falta_justificada": "J"}


def _texto(valor) -> str:
    return str(valor) if valor not in (None, "") else "—"


def _data_txt(valor) -> str:
    if valor is None:
        return "—"
    if isinstance(valor, datetime):
        valor = valor.date()
    return valor.strftime("%d/%m/%Y")


def _secao(elementos: list, estilos: dict, titulo: str) -> None:
    estilo_secao = ParagraphStyle(
        f"secao_{titulo}", fontName="Helvetica-Bold", fontSize=10.5, textColor=colors.white,
        alignment=TA_LEFT, backColor=COR_AZUL_ESCURO, leftIndent=6, spaceBefore=0,
    )
    tabela = Table([[Paragraph(titulo, estilo_secao)]], colWidths=[None])
    tabela.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), COR_AZUL_ESCURO),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
    ]))
    elementos.append(Spacer(1, 10))
    elementos.append(tabela)
    elementos.append(Spacer(1, 6))


def _campo(estilos: dict, rotulo: str, valor: str) -> list:
    return [
        Paragraph(rotulo, ParagraphStyle("rot", fontName="Helvetica-Bold", fontSize=7.5, textColor=colors.grey)),
        Paragraph(valor, ParagraphStyle("val", fontName="Helvetica", fontSize=9.5, textColor=colors.black)),
    ]


def _linha_campos(estilos: dict, largura_total: float, *pares: tuple[str, str]) -> Table:
    """Uma linha com N campos rótulo/valor lado a lado, largura igual."""
    largura_col = largura_total / len(pares)
    celulas = []
    for rotulo, valor in pares:
        conteudo = _campo(estilos, rotulo, valor)
        celulas.append(conteudo)
    # Cada "célula" é uma lista de 2 Parágrafos; a Table espera 1 flowable por
    # célula, por isso agrupamos rótulo+valor numa sub-tabela de 1 coluna.
    linha = []
    for conteudo in celulas:
        sub = Table([[conteudo[0]], [conteudo[1]]], colWidths=[largura_col])
        sub.setStyle(TableStyle([("LEFTPADDING", (0, 0), (-1, -1), 0), ("TOPPADDING", (0, 0), (-1, -1), 1)]))
        linha.append(sub)
    tabela = Table([linha], colWidths=[largura_col] * len(pares))
    tabela.setStyle(TableStyle([("LEFTPADDING", (0, 0), (-1, -1), 0), ("VALIGN", (0, 0), (-1, -1), "TOP")]))
    return tabela


def gerar_pdf_processo_catequisando(
    doc: dict, fase: dict | None, sector: dict | None, presencas: list[dict], ano_letivo: int,
    pessoas: dict | None = None,
) -> bytes:
    pessoas = pessoas or {}
    buffer = io.BytesIO()
    documento = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.5 * cm, bottomMargin=1.5 * cm, leftMargin=1.8 * cm, rightMargin=1.8 * cm,
    )
    e = estilos_documento()
    elementos: list = []
    largura = documento.width

    elementos += bloco_cabecalho(e, largura)

    # --- Título + Ano/Número ---
    estilo_titulo = ParagraphStyle("titulo_ficha", fontName="Helvetica-Bold", fontSize=15, alignment=TA_LEFT)
    estilo_ficha_ref = ParagraphStyle("ficha_ref", fontName="Helvetica", fontSize=10, alignment=TA_LEFT, textColor=colors.grey)
    ano_ficha = doc.get("ficha_ano")
    numero_ficha = doc.get("ficha_numero")
    ref_txt = f"Ano: {_texto(ano_ficha)}   Nº: {_texto(numero_ficha)}"
    linha_titulo = Table(
        [[Paragraph("Ficha do Catecúmeno", estilo_titulo), Paragraph(ref_txt, estilo_ficha_ref)]],
        colWidths=[largura * 0.6, largura * 0.4],
    )
    linha_titulo.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("ALIGN", (1, 0), (1, 0), "RIGHT")]))
    elementos.append(linha_titulo)

    estilo_nome = ParagraphStyle("nome_cat", fontName="Helvetica-Bold", fontSize=13, alignment=TA_CENTER, spaceBefore=8, spaceAfter=4)
    elementos.append(Paragraph(doc["nome"], estilo_nome))

    # --- Dados do Catequisando ---
    _secao(elementos, e, "DADOS DO CATEQUISANDO")
    genero_txt = _ROTULO_GENERO.get(doc.get("genero"), "—")
    elementos.append(_linha_campos(e, largura,
        ("GÉNERO", genero_txt), ("DATA DE NASCIMENTO", _data_txt(doc.get("data_nascimento"))), ("NATURAL DE", _texto(doc.get("natural_de"))),
    ))
    elementos.append(Spacer(1, 4))
    elementos.append(_linha_campos(e, largura,
        ("ESTADO", _texto(doc.get("estado_civil"))), ("PROFISSÃO", _texto(doc.get("profissao"))), ("RESIDÊNCIA", _texto(doc.get("residencia"))),
    ))
    elementos.append(Spacer(1, 4))
    elementos.append(_linha_campos(e, largura,
        ("FASE", fase["nome"] if fase else "—"), ("SECTOR PASTORAL", sector["nome"] if sector else "—"),
        ("SITUAÇÃO", "Crismado" if doc.get("situacao") == "crismado" else "Ativo"),
    ))
    if doc.get("encarregado_nome") or doc.get("encarregado_contacto"):
        elementos.append(Spacer(1, 4))
        elementos.append(_linha_campos(e, largura,
            ("ENCARREGADO DE EDUCAÇÃO", _texto(doc.get("encarregado_nome"))),
            ("CONTACTO", _texto(doc.get("encarregado_contacto"))),
            ("PARENTESCO", _texto(doc.get("encarregado_parentesco"))),
        ))

    # --- Filiação ---
    pai = pessoas.get("pai") or {}
    mae = pessoas.get("mae") or {}
    if any([pai.get("nome"), mae.get("nome"), doc.get("avo_paterno_nome"), doc.get("avo_paterna_nome"),
            doc.get("avo_materno_nome"), doc.get("avo_materna_nome")]):
        _secao(elementos, e, "FILIAÇÃO")
        elementos.append(_linha_campos(e, largura,
            ("FILHO(A) DE (PAI)", _texto(pai.get("nome"))), ("NATURAL DE", _texto(pai.get("natural_de"))),
        ))
        elementos.append(Spacer(1, 3))
        elementos.append(_linha_campos(e, largura,
            ("ESTADO", _texto(pai.get("estado_civil"))), ("PROFISSÃO", _texto(pai.get("profissao"))), ("RESIDÊNCIA", _texto(pai.get("residencia"))),
        ))
        elementos.append(Spacer(1, 6))
        elementos.append(_linha_campos(e, largura,
            ("E DE (MÃE)", _texto(mae.get("nome"))), ("NATURAL DE", _texto(mae.get("natural_de"))),
        ))
        elementos.append(Spacer(1, 3))
        elementos.append(_linha_campos(e, largura,
            ("ESTADO", _texto(mae.get("estado_civil"))), ("PROFISSÃO", _texto(mae.get("profissao"))), ("RESIDÊNCIA", _texto(mae.get("residencia"))),
        ))
        elementos.append(Spacer(1, 6))
        elementos.append(_linha_campos(e, largura,
            ("AVÔ PATERNO", _texto(doc.get("avo_paterno_nome"))), ("AVÓ PATERNA", _texto(doc.get("avo_paterna_nome"))),
        ))
        elementos.append(Spacer(1, 3))
        elementos.append(_linha_campos(e, largura,
            ("AVÔ MATERNO", _texto(doc.get("avo_materno_nome"))), ("AVÓ MATERNA", _texto(doc.get("avo_materna_nome"))),
        ))

    # --- Padrinhos ---
    padrinho = pessoas.get("padrinho") or {}
    madrinha = pessoas.get("madrinha") or {}
    if padrinho.get("nome") or madrinha.get("nome"):
        _secao(elementos, e, "PADRINHOS")
        elementos.append(_linha_campos(e, largura,
            ("PADRINHO", _texto(padrinho.get("nome"))), ("ESTADO", _texto(padrinho.get("estado_civil"))),
            ("PROFISSÃO", _texto(padrinho.get("profissao"))),
        ))
        elementos.append(Spacer(1, 3))
        elementos.append(_linha_campos(e, largura, ("RESIDÊNCIA", _texto(padrinho.get("residencia"))), ("", "")))
        elementos.append(Spacer(1, 6))
        elementos.append(_linha_campos(e, largura,
            ("MADRINHA", _texto(madrinha.get("nome"))), ("ESTADO", _texto(madrinha.get("estado_civil"))),
            ("PROFISSÃO", _texto(madrinha.get("profissao"))),
        ))
        elementos.append(Spacer(1, 3))
        elementos.append(_linha_campos(e, largura, ("RESIDÊNCIA", _texto(madrinha.get("residencia"))), ("", "")))

    # --- Presenças do ano corrente / fase corrente, em grelha mensal R/C ---
    _secao(elementos, e, f"PRESENÇAS — ANO LETIVO {ano_letivo}")
    estilo_nota = ParagraphStyle("nota_rc", fontName="Helvetica-Oblique", fontSize=8, textColor=colors.grey)
    elementos.append(Paragraph(
        "R = Sábado (Reunião) · C = Domingo (Celebração) · * = Catequese Quaresmal", estilo_nota,
    ))
    elementos.append(Spacer(1, 6))

    por_mes: dict[int, dict[str, list[str]]] = {m: {"R": [], "C": []} for m in range(1, 13)}
    for p in presencas:
        data_p = p["data"]
        if isinstance(data_p, datetime):
            data_p = data_p.date()
        marca = _MARCA_STATUS.get(p["status"], "?")
        if esta_em_quaresma(data_p):
            marca += "*"
        chave = "R" if data_p.weekday() == 5 else "C" if data_p.weekday() == 6 else None
        if chave:
            por_mes[data_p.month][chave].append(marca)

    estilo_cab = ParagraphStyle("cab_pres", fontName="Helvetica-Bold", fontSize=8.5, textColor=colors.white, alignment=TA_CENTER)
    estilo_cab_esq = ParagraphStyle("cab_pres_esq", parent=estilo_cab, alignment=TA_LEFT)
    estilo_cel = ParagraphStyle("cel_pres", fontName="Helvetica", fontSize=8.5, textColor=colors.black, alignment=TA_CENTER)
    estilo_cel_esq = ParagraphStyle("cel_pres_esq", parent=estilo_cel, alignment=TA_LEFT)

    linhas_presenca = [[
        Paragraph("MÊS", estilo_cab_esq), Paragraph("SÁBADOS (R)", estilo_cab), Paragraph("DOMINGOS (C)", estilo_cab),
    ]]
    for m in range(1, 13):
        r_txt = " ".join(por_mes[m]["R"]) or "—"
        c_txt = " ".join(por_mes[m]["C"]) or "—"
        linhas_presenca.append([Paragraph(_MESES[m - 1], estilo_cel_esq), Paragraph(r_txt, estilo_cel), Paragraph(c_txt, estilo_cel)])

    tabela_presenca = Table(linhas_presenca, colWidths=[largura * 0.3, largura * 0.35, largura * 0.35], repeatRows=1)
    estilo_tabela_p = [
        ("BACKGROUND", (0, 0), (-1, 0), COR_AZUL_ESCURO),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#DDDDDD")),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
    ]
    for i in range(1, len(linhas_presenca)):
        if i % 2 == 0:
            estilo_tabela_p.append(("BACKGROUND", (0, i), (-1, i), COR_LINHA_ALTERNADA))
    tabela_presenca.setStyle(TableStyle(estilo_tabela_p))
    elementos.append(tabela_presenca)

    # --- Eleição e Escrutínios (opcional) ---
    tem_eleicao = any([
        doc.get("eleicao_data"), doc.get("escrutinio_1_data"), doc.get("escrutinio_2_data"), doc.get("escrutinio_3_data"),
    ])
    if tem_eleicao:
        _secao(elementos, e, "ELEIÇÃO E ESCRUTÍNIOS")
        elementos.append(_linha_campos(e, largura, ("DATA DA ELEIÇÃO", _data_txt(doc.get("eleicao_data"))), ("", "")))
        elementos.append(Spacer(1, 4))
        elementos.append(_linha_campos(e, largura,
            ("1º ESCRUTÍNIO", _data_txt(doc.get("escrutinio_1_data"))),
            ("2º ESCRUTÍNIO", _data_txt(doc.get("escrutinio_2_data"))),
            ("3º ESCRUTÍNIO", _data_txt(doc.get("escrutinio_3_data"))),
        ))

    # --- Baptismo (opcional) ---
    tem_baptismo = any([doc.get("baptismo_local"), doc.get("baptismo_data"), doc.get("baptismo_certidao_url")])
    if tem_baptismo:
        _secao(elementos, e, "BAPTISMO")
        certidao_url = doc.get("baptismo_certidao_url")
        if certidao_url:
            estilo_link = ParagraphStyle("link_certidao", fontName="Helvetica", fontSize=9.5, textColor=colors.blue)
            certidao_flowable = Paragraph(f'<link href="{certidao_url}">Ver certidão (Google Drive)</link>', estilo_link)
        else:
            certidao_flowable = Paragraph("—", ParagraphStyle("sem_certidao", fontName="Helvetica", fontSize=9.5))
        linha_bapt = Table(
            [[
                Table([[Paragraph("LOCAL", ParagraphStyle("r1", fontName="Helvetica-Bold", fontSize=7.5, textColor=colors.grey))],
                       [Paragraph(_texto(doc.get("baptismo_local")), ParagraphStyle("v1", fontName="Helvetica", fontSize=9.5))]]),
                Table([[Paragraph("DATA", ParagraphStyle("r2", fontName="Helvetica-Bold", fontSize=7.5, textColor=colors.grey))],
                       [Paragraph(_data_txt(doc.get("baptismo_data")), ParagraphStyle("v2", fontName="Helvetica", fontSize=9.5))]]),
                Table([[Paragraph("CERTIDÃO", ParagraphStyle("r3", fontName="Helvetica-Bold", fontSize=7.5, textColor=colors.grey))],
                       [certidao_flowable]]),
            ]],
            colWidths=[largura / 3] * 3,
        )
        linha_bapt.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0)]))
        elementos.append(linha_bapt)

    # --- Observações ---
    if doc.get("observacoes"):
        _secao(elementos, e, "OBSERVAÇÕES")
        elementos.append(Paragraph(doc["observacoes"], e["corpo"]))

    elementos += bloco_assinatura(e, cargo="Coordenador(a) da Catequese")

    documento.build(elementos)
    return buffer.getvalue()
