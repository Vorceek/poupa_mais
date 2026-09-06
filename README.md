# Poupa+

Aplicativo de gestão de finanças pessoais desenvolvido para a disciplina de Desenvolvimento de Aplicações Mobile (turma 28743, EAD54-12), a partir do documento de concepção, requisitos e prototipação da Atividade 1 (disponível em `docs/`).

A ideia central do projeto: registrar um gasto precisa levar menos de dez segundos, senão a pessoa abandona o controle financeiro em poucas semanas.

| | |
|---|---|
| Aluno | Vinicios Andrei Mensen |
| Curso | Análise e Desenvolvimento de Sistemas |
| Professor | Alysson Borges |
| Stack | Flutter 3 (Dart 3), SQLite, Provider (MVVM), fl_chart, AwesomeAPI |

## Funcionalidades

- Lançamento de despesas e receitas em 3 toques: botão flutuante em todas as abas, valor com foco automático, data preenchida com o dia atual e categoria sugerida pelo último uso (RF03, RNF02)
- Painel do mês com saldo disponível, receitas x despesas e barra agregada do orçamento (RF07)
- Extrato agrupado por dia, com busca textual, filtros por mês/tipo/categoria, edição por toque e exclusão por gesto com confirmação (RF05, RF08)
- Orçamento por categoria com semáforo de cores: verde até 79%, âmbar aos 80%, vermelho ao estourar, com alerta visual na hora em que o gasto cruza o limite (RF09, RF10)
- Metas de economia com valor-alvo, prazo e o aporte mensal necessário já calculado; aportes viram despesa na categoria Poupança para não inflar o saldo (RF11, RN06, RN07)
- Relatórios: gráfico de rosca das despesas por categoria e barras com a evolução de 6 meses (RF12)
- Lançamentos recorrentes mensais ou semanais gerados automaticamente (RF13)
- Exportação do mês em CSV (RF14) e cotações de dólar, euro e bitcoin via API, com cache para uso offline
- Funciona 100% offline: todas as funções essenciais operam sem internet, com banco SQLite local e gravação transacional (RNF03, RNF09)
- Conta opcional: dá para usar sem cadastro (modo local); senhas guardadas com hash SHA-256 e sal; opção de excluir a conta e todos os dados, conforme a LGPD (RF01, RNF04, RNF05)

## Integração com API (comunicação com servidores)

O painel consome a [AwesomeAPI de cotações](https://docs.awesomeapi.com.br/api-de-moedas) por HTTPS:

```
GET https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL,BTC-BRL
```

A resposta JSON é convertida nos objetos de `lib/models/cotacao.dart` e a última resposta válida fica em cache local (`shared_preferences`). Sem conexão, o card mostra os valores salvos com um indicador de offline, mantendo a proposta offline-first do app.

## Arquitetura

Camadas com MVVM (RNF10), como definido na seção 5.1 do documento de concepção:

```
lib/
├── core/        # tema (sistema de design da seção 4.1), formatação pt_BR, validações RN01 a RN03
├── models/      # entidades: Usuario, Categoria, Lancamento, Orcamento, Meta/Aporte, Cotacao
├── data/        # repositórios SQLite (sqflite) + serviço da API de cotações
├── viewmodels/  # estado com Provider/ChangeNotifier (Sessao, Financas, Categoria, Cotacao)
├── views/       # telas do protótipo (login, onboarding, painel, extrato, orçamentos, metas, relatórios, perfil, categorias)
└── widgets/     # componentes compartilhados
```

Os valores monetários circulam como inteiros em centavos para evitar erros de arredondamento de ponto flutuante.

## Como executar

Pré-requisitos: [Flutter](https://docs.flutter.dev/get-started/install) (canal estável) e Android Studio com um AVD (ex.: Pixel 6, API 34 ou superior).

```bash
git clone <este-repositorio>
cd poupa_mais
flutter pub get
flutter run          # com o emulador aberto ou um aparelho via USB
```

Testes e análise estática:

```bash
flutter test         # 25 testes de unidade e widget (regras RN01 a RN07, RF13, formatação, API)
flutter analyze
```

Para gerar o APK de depuração: `flutter build apk --debug` (sai em `build/app/outputs/flutter-apk/`).

## Documentação

- `docs/RELATORIO_TECNICO.md`: relatório técnico com o processo de desenvolvimento, as escolhas feitas e as soluções adotadas
- `docs/Concepcao_Requisitos_Prototipacao.pdf`: documento da Atividade 1 (requisitos, matriz de decisão da plataforma e wireframes)
- `docs/apresentacao.html`: slides da apresentação final

## Licença

Projeto acadêmico, sem fins comerciais.
