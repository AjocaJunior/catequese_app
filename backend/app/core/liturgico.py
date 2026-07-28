"""
Cálculos do calendário litúrgico que dependem só da data (sem precisar de
nenhuma API externa) — usados para destacar os dias de Catequese Quaresmal
dentro das presenças normais, em vez de um registo separado.
"""
from datetime import date, timedelta


def calcular_pascoa(ano: int) -> date:
    """Data da Páscoa (calendário Gregoriano) para o ano indicado, pelo
    algoritmo de Meeus/Jones/Butcher — o método padrão para isto."""
    a = ano % 19
    b = ano // 100
    c = ano % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    mes = (h + l - 7 * m + 114) // 31
    dia = ((h + l - 7 * m + 114) % 31) + 1
    return date(ano, mes, dia)


def periodo_quaresma(ano: int) -> tuple[date, date]:
    """(Quarta-feira de Cinzas, Sábado Santo) — período da Quaresma para o
    ano indicado. A Quarta-feira de Cinzas é 46 dias antes da Páscoa."""
    pascoa = calcular_pascoa(ano)
    cinzas = pascoa - timedelta(days=46)
    sabado_santo = pascoa - timedelta(days=1)
    return cinzas, sabado_santo


def esta_em_quaresma(dia: date) -> bool:
    inicio, fim = periodo_quaresma(dia.year)
    return inicio <= dia <= fim
