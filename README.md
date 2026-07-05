# App de Gestão Catequética

Paróquia de Nossa Senhora da Assunção – Liberdade, Comunidade Santa Ana de Mastrong.
Desenvolvimento incremental, módulo a módulo.

## Stack
- **Backend:** Python + FastAPI (async), MongoDB via Motor
- **Base de dados:** MongoDB Atlas (tier gratuito M0)
- **Frontend:** Flutter (Web + Android/APK)
- **PDFs:** reportlab (fichas de retiro, listas, relatórios, processos individuais — cabeçalho institucional partilhado)
- **Hospedagem:** Render (free tier) — backend em produção; frontend por agora distribuído como APK
- **Autenticação:** JWT, com 2 perfis — **admin** e **catequista**

## Funcionalidades

- **Catequistas:** registo/login; primeiro utilizador registado torna-se admin automaticamente; admin promove/despromove outros
- **Fases catequéticas:** nome, catecismo, local, link do programa (PDF no Drive), catequistas atribuídos (vários por fase)
- **Catequisandos:** CRUD por fase (e opcionalmente por sector pastoral), encarregado de educação, importação em massa via Excel, mudança de fase, processo individual (dados + histórico de presenças) com impressão em PDF
- **Presenças:** 3 estados (Presença / Falta / Falta Justificada), só o(s) catequista(s) atribuído(s) à fase (ou admin) podem marcar; relatório agregado por fase em PDF
- **Retiros:** fases e/ou sectores participantes, oradores, tema, programa do dia em tabela, impressão em PDF com espaço de assinatura do coordenador
- **Ministérios e Sectores:** estrutura organizacional (ministério → sectores → responsável), sectores sem encontro regular são suportados (ex: Finanças); script de seed para popular a estrutura real de uma vez
- **Eventos da Paróquia:** datas de festas, batismos, crismas, etc.
- **Área pública (sem login):** retiros, eventos, sectores com encontro, organograma completo, links úteis (calendário litúrgico, catecismo, site da paróquia)
- **Permissões:** criar/editar é geralmente aberto a qualquer catequista; apagar é restrito a admin

## Estrutura de pastas

```
catequese-app/
├── backend/
│   ├── app/
│   │   ├── core/        # config, ligação à BD, segurança/JWT, permissões partilhadas
│   │   ├── models/      # esquemas Pydantic (um por entidade)
│   │   ├── routers/     # endpoints da API (um por entidade, + publico.py sem autenticação)
│   │   ├── services/    # geração de PDFs (cabeçalho comum + um gerador por documento)
│   │   └── main.py
│   ├── scripts/         # seed_ministerios.py — popula a estrutura real da paróquia
│   ├── requirements.txt
│   ├── render.yaml
│   └── .env.example
└── frontend/
    └── lib/
        ├── config/       # api_config.dart
        ├── models/       # um por entidade
        ├── services/     # um cliente por entidade + api_client.dart (base HTTP)
        ├── screens/       # ecrãs de autenticação, gestão (por entidade), detalhe, e público
        └── main.dart
```

## Como correr localmente

### 1. Base de dados (MongoDB Atlas — gratuito)
Cluster M0, criar utilizador em "Database Access", e em "Network Access" permitir `0.0.0.0/0`.

### 2. Backend
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Linux/Mac: source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env     # preencher MONGODB_URI e JWT_SECRET
uvicorn app.main:app --reload
```
Testar em `http://localhost:8000/health` e `http://localhost:8000/docs`.

**Popular a estrutura de ministérios/sectores** (uma vez, idempotente):
```bash
pip install requests
python scripts/seed_ministerios.py
```

### 3. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Deploy

### Backend → Render (já em produção)
Root Directory `backend`, variáveis `MONGODB_URI` e `JWT_SECRET` no painel. No plano free, o serviço "adormece" após 15 min de inatividade (~30-60s a acordar no pedido seguinte).

### Frontend → APK (distribuição atual)
```bash
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://o-meu-servico.onrender.com
```
APK fica em `frontend/build/app/outputs/flutter-apk/app-release.apk`.

### Frontend Web (futuro)
Render Static Site, root `frontend`, publish directory `build/web` — build feito com o mesmo `--dart-define=API_BASE_URL=...`. Quando ativo, mudar `CORS_ORIGINS` do backend do `*` para o domínio real.

## Ideias para mais tarde
- Perfil **"responsável"** (além de catequista/admin): líder de sector, para marcar presenças das atividades do seu próprio sector
- Coordenadores de ministério a criar retiros para todos os sectores do seu ministério de uma vez
