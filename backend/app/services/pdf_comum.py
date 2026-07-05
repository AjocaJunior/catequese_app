"""
Elementos de PDF partilhados por todos os documentos da paróquia
(retiro, listas de catequisandos, etc.), para manter o mesmo
cabeçalho em todos os documentos impressos pela aplicação.

Para mudar o cabeçalho (nome da paróquia, comunidade, etc.), edita
só as constantes aqui em baixo — todos os PDFs são atualizados.
"""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.lib.utils import ImageReader
from reportlab.platypus import HRFlowable, Image, Paragraph, Spacer, Table, TableStyle

# --- Dados do cabeçalho: edita aqui se mudarem ---
NOME_ARQUIDIOCESE = "ARQUIDIOCESE DE MAPUTO"
NOME_PAROQUIA = "Paróquia de Nossa Senhora da Assunção – Liberdade"
NOME_COMUNIDADE = "Comunidade Santa Ana de Mastrong"
NOME_MINISTERIO = "MINISTÉRIO DA CATEQUESE E FORMAÇÃO PERMANENTE"

# Logótipos: ficheiros dentro de app/assets/. Se não existirem, o cabeçalho
# é gerado só com texto (não falha).
ASSETS_DIR = Path(__file__).resolve().parent.parent / "assets"
LOGO_ESQUERDA = ASSETS_DIR / "logo_assuncao.jpg"
LOGO_DIREITA = ASSETS_DIR / "logo_comunidade.jpg"

COR_DOURADO = colors.HexColor("#B8964F")
COR_AZUL_ESCURO = colors.HexColor("#1F2E4A")
COR_CINZA = colors.HexColor("#8A8A8A")
COR_FUNDO_CLARO = colors.HexColor("#F5F0E6")
COR_LINHA_ALTERNADA = colors.HexColor("#F7F7F7")


def estilos_documento() -> dict:
    base = getSampleStyleSheet()
    return {
        "arquidiocese": ParagraphStyle(
            "arquidiocese", parent=base["Normal"], fontName="Helvetica",
            fontSize=9, textColor=COR_CINZA, alignment=TA_CENTER,
        ),
        "paroquia": ParagraphStyle(
            "paroquia", parent=base["Normal"], fontName="Helvetica-Bold",
            fontSize=13, textColor=COR_AZUL_ESCURO, alignment=TA_CENTER, spaceBefore=2,
        ),
        "comunidade": ParagraphStyle(
            "comunidade", parent=base["Normal"], fontName="Helvetica-Bold",
            fontSize=11, textColor=COR_AZUL_ESCURO, alignment=TA_CENTER,
        ),
        "ministerio": ParagraphStyle(
            "ministerio", parent=base["Normal"], fontName="Helvetica",
            fontSize=8, textColor=COR_CINZA, alignment=TA_CENTER, spaceBefore=2,
        ),
        "titulo_doc": ParagraphStyle(
            "titulo_doc", parent=base["Normal"], fontName="Helvetica-Bold",
            fontSize=15, textColor=colors.black, alignment=TA_CENTER, spaceBefore=14, spaceAfter=14,
        ),
        "secao": ParagraphStyle(
            "secao", parent=base["Normal"], fontName="Helvetica-Bold", fontSize=9,
            textColor=COR_DOURADO, alignment=TA_CENTER, spaceBefore=8, spaceAfter=8,
        ),
        "campo": ParagraphStyle(
            "campo", parent=base["Normal"], fontName="Helvetica", fontSize=11,
            textColor=colors.black, alignment=TA_LEFT, leading=14,
        ),
        "corpo": ParagraphStyle(
            "corpo", parent=base["Normal"], fontName="Helvetica", fontSize=11,
            textColor=colors.black, alignment=TA_LEFT, leading=15,
        ),
        "assinatura": ParagraphStyle(
            "assinatura", parent=base["Normal"], fontName="Helvetica", fontSize=9,
            textColor=colors.black, alignment=TA_CENTER,
        ),
        "rodape": ParagraphStyle(
            "rodape", parent=base["Normal"], fontName="Helvetica-Oblique", fontSize=7,
            textColor=COR_CINZA, alignment=TA_CENTER,
        ),
    }


def campo_rotulo_valor(estilos: dict, rotulo: str, valor: str) -> Paragraph:
    """Um 'campo' tipo DATA / ORADOR(A): rótulo pequeno cinzento por cima, valor por baixo."""
    valor_seguro = valor if valor else "—"
    return Paragraph(
        f'<font size="8" color="#8A8A8A">{rotulo}</font><br/>'
        f'<font size="11" color="#000000">{valor_seguro}</font>',
        estilos["campo"],
    )


def _imagem_proporcional(caminho: Path, lado_max: float):
    """Carrega uma imagem mantendo a proporção original, dentro de um quadrado
    de lado_max pontos. Devolve None se o ficheiro não existir (o cabeçalho
    continua a funcionar, só sem essa imagem)."""
    if not caminho.exists():
        return None
    largura_original, altura_original = ImageReader(str(caminho)).getSize()
    escala = lado_max / max(largura_original, altura_original)
    return Image(
        str(caminho),
        width=largura_original * escala,
        height=altura_original * escala,
    )


def bloco_cabecalho(estilos: dict, largura_total: float) -> list:
    """Devolve os flowables do cabeçalho institucional (topo de todos os PDFs).
    largura_total deve ser doc.width, para calcular a coluna central."""
    coluna_logo = 2.6 * cm

    texto_central = [
        Paragraph(NOME_ARQUIDIOCESE, estilos["arquidiocese"]),
        Paragraph(NOME_PAROQUIA, estilos["paroquia"]),
        Paragraph(NOME_COMUNIDADE, estilos["comunidade"]),
        Paragraph(NOME_MINISTERIO, estilos["ministerio"]),
    ]

    logo_esq = _imagem_proporcional(LOGO_ESQUERDA, coluna_logo - 0.3 * cm)
    logo_dir = _imagem_proporcional(LOGO_DIREITA, coluna_logo - 0.3 * cm)

    linha_cabecalho = Table(
        [[logo_esq or "", texto_central, logo_dir or ""]],
        colWidths=[coluna_logo, largura_total - (2 * coluna_logo), coluna_logo],
    )
    linha_cabecalho.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("ALIGN", (0, 0), (0, 0), "CENTER"),
        ("ALIGN", (2, 0), (2, 0), "CENTER"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
    ]))

    return [
        linha_cabecalho,
        Spacer(1, 6),
        HRFlowable(width="100%", thickness=1.5, color=COR_DOURADO),
        Spacer(1, 4),
    ]


def bloco_assinatura(estilos: dict, cargo: str = "Coordenador(a) da Catequese") -> list:
    """Linha de assinatura centrada, com o cargo por baixo e a data no fim,
    para o coordenador assinar no papel impresso."""
    return [
        Spacer(1, 46),
        Paragraph("_______________________________", estilos["assinatura"]),
        Paragraph(cargo, estilos["assinatura"]),
        Spacer(1, 28),
        Paragraph("Data: _____ / _____ / ________", estilos["assinatura"]),
    ]
