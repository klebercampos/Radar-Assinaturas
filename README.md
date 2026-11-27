# Radar Assinaturas

App Flutter para monitorar assinaturas recorrentes e *free trials*, com alertas de cobrança iminente, resumo financeiro e persistência local.

## Como rodar

```bash
flutter pub get
flutter run                 # dispositivo / emulador
flutter run -d web-server   # pré-visualização no navegador
```

## Funcionalidades

- Dashboard com gasto mensal, anual projetado, valor em risco e economia com cancelamentos
- Alertas urgentes (próximos 3 dias)
- Cadastro/edição com presets, trial vs recorrente, atalhos de data (+7/+14/+30)
- Filtros: Ativas, Trials, Vencendo em 7 dias, Canceladas + busca
- Marcar como cancelada / excluir com confirmação
- Tema claro/escuro, PT-BR, `R$` e `dd/MM/yyyy`
- Seed de 4 exemplos na primeira abertura + “Limpar dados de exemplo”
- Notificações locais (mobile); desabilitadas com segurança na Web (`kIsWeb`)

## Estrutura

```
lib/
  models/          # Subscription e enums
  services/        # Storage, notificações, repositório
  screens/         # Dashboard, formulário, detalhes
  widgets/         # Cards, tiles, filtros, ícones
  theme/           # Material 3 light/dark
  main.dart
```

Persistência: `shared_preferences` + JSON (sem `build_runner` / freezed / hive).

## Deploy (GitHub Pages)

Cada push em `main` dispara o workflow que faz `flutter build web` e publica em GitHub Pages.

**URL:** https://klebercampos.github.io/Radar-Assinaturas/

**Ativar Pages (obrigatório, uma vez — o `GITHUB_TOKEN` não consegue criar o site sozinho):**

1. Abra [Settings → Pages](https://github.com/klebercampos/Radar-Assinaturas/settings/pages)
2. Em *Build and deployment → Source*, escolha **GitHub Actions**
3. Reexecute o workflow (*Actions → Deploy Flutter Web to GitHub Pages → Run workflow*) ou faça um push em `main`

Especificação completa: [`prompt_radar_assinaturas.md`](prompt_radar_assinaturas.md).
