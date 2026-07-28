import io
from datetime import date

from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.services.pdf_comum import bloco_cabecalho, estilos_documento, formatar_data_extenso

_TITULOS = {
    "baptismo": "Ficha de Baptismo",
    "primeira_comunhao": "Ficha de 1ª Comunhão",
    "crisma": "Ficha de Crisma",
}

_ROTULO_GENERO = {"masculino": "Masculino", "feminino": "Feminino"}


def _idade(data_nascimento, referencia=None) -> str:
    if data_nascimento is None:
        return "—"
    ref = referencia or date.today()
    idade = ref.year - data_nascimento.year - ((ref.month, ref.day) < (data_nascimento.month, data_nascimento.day))
    return str(idade)


def _texto_pai_mae(rotulo: str, pessoa: dict | None) -> str:
    p = pessoa or {}
    return (
        f"{rotulo} <b>{p.get('nome') or '—'}</b>, natural de <b>{p.get('natural_de') or '—'}</b>, "
        f"na província de <b>{p.get('provincia') or '—'}</b>, no estado de <b>{p.get('estado_civil') or '—'}</b>, "
        f"profissão <b>{p.get('profissao') or '—'}</b>"
    )


def _texto_padrinho(rotulo: str, pessoa: dict | None) -> str:
    p = pessoa or {}
    return (
        f"<b>{rotulo} {p.get('nome') or '—'}</b> estado civil <b>{p.get('estado_civil') or '—'}</b> "
        f"profissão <b>{p.get('profissao') or '—'}</b><br/>"
        f"Residente <b>{p.get('residencia') or '—'}</b>, na província de <b>{p.get('provincia') or '—'}</b>, "
        f"pertencem a comunidade <b>{p.get('comunidade') or '—'}</b> contacto <b>{p.get('contacto') or '—'}</b>."
    )


def gerar_pdf_ficha_sacramento(tipo: str, doc: dict, pessoas: dict, nucleo_nome: str | None) -> bytes:
    """tipo: 'baptismo' | 'primeira_comunhao' | 'crisma' — mesma estrutura para
    os 3, só as linhas de referência ao sacramento e o título é que mudam.
    pessoas: {'pai', 'mae', 'padrinho', 'madrinha'} — dicts já resolvidos (ou None)."""
    buffer = io.BytesIO()
    documento = SimpleDocTemplate(
        buffer, pagesize=A4, topMargin=1.6 * cm, bottomMargin=1.6 * cm, leftMargin=2.2 * cm, rightMargin=2.2 * cm,
    )
    e = estilos_documento()
    elementos: list = []
    largura = documento.width

    elementos += bloco_cabecalho(e, largura)
    elementos.append(Spacer(1, 14))

    titulo = _TITULOS.get(tipo, "Ficha de Sacramento")
    estilo_titulo = ParagraphStyle(
        "titulo_ficha_sacr", fontName="Helvetica-Bold", fontSize=14, alignment=TA_CENTER, spaceAfter=18,
    )
    elementos.append(Paragraph(titulo.upper(), estilo_titulo))

    estilo_corpo = ParagraphStyle(
        "corpo_ficha_sacr", fontName="Helvetica", fontSize=10.5, alignment=TA_JUSTIFY, leading=16, spaceAfter=4,
    )

    baptismo_txt = (
        f"Baptizado aos <b>{formatar_data_extenso(doc.get('baptismo_data'))}</b> na paróquia/Igreja "
        f"<b>{doc.get('baptismo_local') or '—'}</b>, da Arquidiocese de <b>{doc.get('baptismo_arquidiocese') or '—'}</b>."
    )
    comunhao_txt = f"Fez a sua Primeira Comunhão aos <b>{formatar_data_extenso(doc.get('primeira_comunhao_data'))}</b>."

    referencias: list[str] = []
    if tipo == "baptismo":
        referencias.append(
            f"Recebeu o seu Baptismo no dia <b>{formatar_data_extenso(doc.get('baptismo_data'))}</b> na "
            f"paróquia/Igreja <b>{doc.get('baptismo_local') or '—'}</b>, da Arquidiocese de "
            f"<b>{doc.get('baptismo_arquidiocese') or '—'}</b>."
        )
        evento_data = doc.get("baptismo_data")
        livro, numero_registo, pagina = doc.get("baptismo_livro"), doc.get("baptismo_numero_registo"), doc.get("baptismo_pagina")
    elif tipo == "primeira_comunhao":
        referencias.append(baptismo_txt)
        hora_txt = f", às <b>{doc['primeira_comunhao_hora']}</b> horas." if doc.get("primeira_comunhao_hora") else "."
        referencias.append(
            f"Recebeu a sua Primeira Comunhão no dia <b>{formatar_data_extenso(doc.get('primeira_comunhao_data'))}</b>{hora_txt}"
        )
        evento_data = doc.get("primeira_comunhao_data")
        livro = doc.get("primeira_comunhao_livro")
        numero_registo = doc.get("primeira_comunhao_numero_registo")
        pagina = doc.get("primeira_comunhao_pagina")
    else:
        referencias.append(baptismo_txt)
        referencias.append(comunhao_txt)
        hora_txt = f", às <b>{doc['crisma_hora']}</b> horas." if doc.get("crisma_hora") else "."
        referencias.append(f"Recebeu a sua Crisma no dia <b>{formatar_data_extenso(doc.get('crisma_data'))}</b>{hora_txt}")
        evento_data = doc.get("crisma_data")
        livro, numero_registo, pagina = doc.get("crisma_livro"), doc.get("crisma_numero_registo"), doc.get("crisma_pagina")

    for linha in referencias:
        elementos.append(Paragraph(linha, estilo_corpo))
    elementos.append(Spacer(1, 8))

    genero_txt = _ROTULO_GENERO.get(doc.get("genero"), "—")
    elementos.append(Paragraph(
        f"Nome completo <b>{doc['nome']}</b> &nbsp;&nbsp;&nbsp;&nbsp; "
        f"Idade <b>{_idade(doc.get('data_nascimento'), evento_data)}</b> &nbsp;&nbsp;&nbsp;&nbsp; "
        f"Sexo <b>{genero_txt}</b>",
        estilo_corpo,
    ))
    elementos.append(Paragraph(
        f"Data de nascimento <b>{formatar_data_extenso(doc.get('data_nascimento'))}</b>, "
        f"Natural de <b>{doc.get('natural_de') or '—'}</b>",
        estilo_corpo,
    ))
    elementos.append(Spacer(1, 8))

    elementos.append(Paragraph(_texto_pai_mae("Filho(a) de", pessoas.get("pai")), estilo_corpo))
    elementos.append(Paragraph(_texto_pai_mae("e de", pessoas.get("mae")), estilo_corpo))
    elementos.append(Spacer(1, 10))

    elementos.append(Paragraph(
        f"<b>Núcleo</b> a que pertencem os pais: <b>{nucleo_nome or '—'}</b>, "
        f"da comunidade <b>{doc.get('nucleo_comunidade') or '—'}</b>",
        estilo_corpo,
    ))
    elementos.append(Paragraph(
        f"Nome dos avós paternos: <b>{doc.get('avo_paterno_nome') or '—'}</b> e <b>{doc.get('avo_paterna_nome') or '—'}</b>",
        estilo_corpo,
    ))
    elementos.append(Paragraph(
        f"Nome dos avós maternos: <b>{doc.get('avo_materno_nome') or '—'}</b> e <b>{doc.get('avo_materna_nome') or '—'}</b>",
        estilo_corpo,
    ))
    elementos.append(Spacer(1, 12))

    elementos.append(Paragraph(_texto_padrinho("Padrinho", pessoas.get("padrinho")), estilo_corpo))
    elementos.append(Spacer(1, 8))
    elementos.append(Paragraph(_texto_padrinho("Madrinha", pessoas.get("madrinha")), estilo_corpo))
    elementos.append(Spacer(1, 12))

    elementos.append(Paragraph(
        f"Fica registado(a) no livro <b>{livro or '—'}</b> com o nº. <b>{numero_registo or '—'}</b>. "
        f"Página <b>{pagina or '—'}</b>",
        estilo_corpo,
    ))
    elementos.append(Spacer(1, 44))

    estilo_assinatura = ParagraphStyle("assin_ficha_sacr", fontName="Helvetica", fontSize=9.5, alignment=TA_CENTER)
    largura_col = largura / 3
    tabela_assinaturas = Table(
        [[
            Paragraph("_______________________", estilo_assinatura),
            Paragraph("_______________________", estilo_assinatura),
            Paragraph("_______________________", estilo_assinatura),
        ], [
            Paragraph("O Animador Do Núcleo", estilo_assinatura),
            Paragraph("Coordenação Da Catequese", estilo_assinatura),
            Paragraph("O Pároco", estilo_assinatura),
        ]],
        colWidths=[largura_col, largura_col, largura_col],
    )
    tabela_assinaturas.setStyle(TableStyle([
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
    ]))
    elementos.append(tabela_assinaturas)

    documento.build(elementos)
    return buffer.getvalue()
