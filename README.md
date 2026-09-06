# Poupa+ 💰

> Aplicativo de gestão de finanças pessoais — registrar um gasto precisa levar **menos de dez segundos**.

Projeto da disciplina **Desenvolvimento de Aplicações Mobile** (turma 28743 · EAD54-12), implementado a partir do [documento de concepção, requisitos e prototipação](docs/) da Atividade 1.

| | |
|---|---|
| **Aluno** | Vinicios Andrei Mensen |
| **Curso** | Análise e Desenvolvimento de Sistemas |
| **Professor** | Alysson Borges |
| **Stack** | Flutter 3 (Dart 3) · SQLite · Provider (MVVM) · fl_chart · AwesomeAPI |

---

## O que o app faz

- **Lançamento em 3 toques** — botão flutuante em todas as abas, valor com foco automático, data preenchida com hoje e categoria sugerida pelo último uso (RF03, RNF02).
- **Painel do mês** — saldo disponível na primeira dobra, receitas x despesas e barra agregada do orçamento (RF07).
- **Extrato** — agrupado por dia, com busca textual, filtros por mês/tipo/categoria, edição por toque e exclusão por gesto com confirmação (RF05, RF08).
- **Orçamentos com semáforo** — teto mensal por categoria; verde até 79 %, âmbar aos 80 %, vermelho ao estourar, com alerta visual imediato ao salvar o gasto que cruza o limite (RF09, RF10).
- **Metas de economia** — valor-alvo, prazo e o aporte mensal necessário já calculado; aportes viram despesa na categoria Poupança para não inflar o saldo (RF11, RN06, RN07).
- **Relatórios** — rosca de despesas por categoria com total no centro e barras da evolução de 6 meses (RF12).
- **Recorrências** — lançamentos mensais ou semanais gerados automaticamente (RF13).
- **Exportação CSV** do mês (RF14) e **cotações ao vivo** de USD/EUR/BTC via API, com cache offline.
- **100 % offline** — todo o essencial funciona sem internet; SQLite local transacional (RNF03, RNF09).
- **Conta opcional** — dá para usar sem cadastro (modo local); senhas com hash SHA-256 + sal; exclusão total de dados em conformidade com a LGPD (RF01, RNF04, RNF05).

## Integração com API (comunicação com servidores)

O painel consome a [AwesomeAPI de cotações](https://docs.awesomeapi.com.br/api-de-moedas) por HTTPS:

```
GET https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL
```

A resposta JSON é desserializada em `lib/models/cotacao.dart` e a última resposta válida fica em cache (`shared_preferences`); sem conexão o card mostra os valores salvos com um indicador de offline — coerente com a proposta *offline-first* do app.

## Arquitetura

Camadas com MVVM (RNF10), como definido na seção 5.1 do documento de concepção:

```
lib/
├── core/        # tema (sistema de design da seção 4.1), formatação pt_BR, validações RN01–RN03
├── models/      # entidades: Usuario, Categoria, Lancamento, Orcamento, Meta/Aporte, Cotacao
├── data/        # repositórios SQLite (sqflite) + serviço da API de cotações
├── viewmodels/  # estado com Provider/ChangeNotifier (Sessao, Financas, Categoria, Cotacao)
├── views/       # 9+ telas do protótipo (login, onboarding, painel, extrato, orçamentos, metas, relatórios, perfil, categorias)
└── widgets/     # componentes compartilhados
```

Valores monetários circulam como **inteiros em centavos**, eliminando erros de arredondamento de ponto flutuante.

## Como executar

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (canal estável) e Android Studio com um AVD (ex.: Pixel 6, API 34+).

```bash
git clone <este-repositorio>
cd poupa_mais
flutter pub get
flutter run          # com o emulador aberto ou um aparelho via USB
```

Testes e análise estática:

```bash
flutter test         # 25 testes de unidade e widget (regras RN01–RN07, RF13, formatação, API)
flutter analyze
```

APK de depuração: `flutter build apk --debug` → `build/app/outputs/flutter-apk/`.

## Documentação

- [`docs/RELATORIO_TECNICO.md`](docs/RELATORIO_TECNICO.md) — relatório técnico: processo de desenvolvimento, escolhas e soluções.
- [`docs/`](docs/) — documento de concepção da Atividade 1 (requisitos, matriz de decisão da plataforma e wireframes).

## Licença

Projeto acadêmico, sem fins comerciais.
