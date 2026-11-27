# Especificação e Prompt — App "Radar Assinaturas" (Flutter)

> **Como usar este arquivo no Cursor:**
> Você pode copiar todo o conteúdo da seção **Prompt Principal** abaixo e colar no chat/agente do Cursor, ou salvar este arquivo na raiz do seu repositório (ex: `SPEC.md`) e pedir no chat: *"Leia o arquivo SPEC.md e implemente o projeto completo passo a passo."*

---

## Prompt Principal (Copiar e Colar no Cursor)

Atue como um **Engenheiro Sênior de Flutter e Especialista em UX/UI**. Quero criar do zero o aplicativo **"Radar Assinaturas"**, um app mobile focado em monitorar assinaturas recorrentes e, principalmente, períodos de teste gratuito (*free trials*) onde cadastramos o cartão de crédito e acabamos esquecendo de cancelar antes da cobrança automática.

### 1. Objetivo e Arquitetura do MVP
* Crie uma arquitetura limpa, modular e funcional em **Flutter (Dart)** com suporte a null-safety.
* **Persistência local:** Utilize `shared_preferences` (serializando uma lista de objetos em JSON) para armazenar os dados localmente. **Não use** ferramentas que exijam geração de código (`build_runner`, `freezed`, `hive_generator`), para manter o projeto leve, fácil de compilar e sem erros de dependência em ambientes web/cloud.
* **Compatibilidade:** O app deve funcionar perfeitamente em telas mobile (iOS e Android) e rodar sem falhas no modo **Flutter Web** (`flutter run -d web-server`) para pré-visualização rápida no navegador.

---

### 2. Funcionalidades Essenciais

#### A. Dashboard Principal (Tela Inicial)
* **Cards de Resumo Financeiro no topo:**
  1. **Gasto Mensal Recorrente (`R$`):** soma de todas as assinaturas ativas convertidas para base mensal (ex.: assinatura anual dividida por 12).
  2. **Gasto Anual Projetado (`R$`):** projeção de gasto nos próximos 12 meses com base nas assinaturas ativas.
  3. **Valor em Risco (`R$`):** soma dos valores de testes grátis (*trials*) ou assinaturas que terão cobrança nos próximos **7 dias**.
* **Seção de Alerta Urgente ("Atenção Imediata"):**
  * Destaque visual no topo (cards com borda/fundo em âmbar ou vermelho suave) exibindo apenas os *trials* e assinaturas prestes a vencer (nos próximos 3 dias ou vencendo hoje).
* **Lista de Assinaturas:**
  * Exibe ícone/categoria, nome do serviço, valor formatado (`R$`), ciclo (*Mensal*, *Anual*, *Semanal*, *Teste Grátis*), cartão cadastrado (ex.: `Nubank •••• 4532`) e badge com contagem regressiva (ex.: *"Vence hoje"*, *"Faltam 2 dias"*, *"Renova em 18 dias"*).

#### B. Cadastro e Edição de Assinatura / Trial
* Formulário rápido, limpo e acessível pelo botão flutuante (`+ Nova Assinatura`):
  * **Presets rápidos no topo:** chips clicáveis para preencher nome/ícone automaticamente (ex.: *Netflix*, *Spotify*, *Amazon Prime*, *ChatGPT Plus*, *iCloud/Google One*, *Adobe*, *Academia*, *Outro*).
  * **Nome do serviço:** campo de texto obrigatório.
  * **Tipo de monitoramento:** seletor segmentado entre **Teste Grátis (Trial)** e **Assinatura Recorrente**.
  * **Valor (`R$`):** valor que será cobrado após o trial ou valor da parcela recorrente.
  * **Ciclo de cobrança:** *Mensal*, *Anual*, *Semanal* ou *Cobrança Única*.
  * **Data da próxima cobrança / Fim do Teste Grátis:** seletor de data (`DatePicker`) com atalhos rápidos (*+7 dias*, *+14 dias*, *+30 dias*) muito úteis para *free trials*.
  * **Cartão / Meio de pagamento:** campo de texto opcional (ex.: *"Inter Virtual"*, *"Nubank 8821"*).
  * **Como / Onde cancelar:** campo opcional para anotar o caminho ou URL de cancelamento (ex.: *"App Store > Assinaturas"* ou *"site.com/conta"*).
  * **Lembrete antecipado:** escolha de quantos dias antes deseja ser alertado (*No dia*, *1 dia antes*, *3 dias antes*, *7 dias antes*).
* **Ações na tela de detalhes/edição:**
  * Botão de destaque **"Marcar como Cancelada"** (move para a aba de canceladas, retira do cálculo de gastos ativos e soma no indicador de *"Economia com Cancelamentos"*).
  * Opção de excluir definitivamente com diálogo de confirmação.

#### C. Filtros e Busca
* Barra de busca por nome do serviço ou cartão.
* Filtros rápidos por abas/chips:
  * **Todas Ativas**
  * **Testes Grátis (Trials)**
  * **Vencendo em 7 dias**
  * **Canceladas**

#### D. Notificações e Alertas
* Implemente um serviço de notificações (`NotificationService`) preparado para `flutter_local_notifications`, encapsulado com verificação `kIsWeb` para que **não quebre a execução no navegador** caso seja testado na Web.

---

### 3. Diretrizes de Design (UI/UX)
* **Estilo Visual:** Fintech moderna, limpa, com excelente legibilidade e hierarquia visual clara (Material 3).
* **Temas:** Suporte automático e manual (botão no topo) para **Modo Escuro (Dark Mode)** e **Modo Claro (Light Mode)**.
* **Paleta de Cores:**
  * Primária: Índigo profundo / Azul-petróleo (`#1E3A8A` / `#0F766E`).
  * Alerta / Risco iminente: Laranja intenso / Vermelho coral (`#EA580C` / `#DC2626`).
  * Economia / Cancelado com sucesso: Verde esmeralda (`#059669`).
* **Localização:** Textos 100% em **Português do Brasil**, valores monetários em Real (`R$ 0,00`) e datas em `dd/MM/yyyy`.
* **Dados Iniciais (Mock):** Na primeira abertura do app (apenas se não houver dados salvos), popule automaticamente 4 exemplos realistas (ex.: *Adobe Creative Cloud - Trial vence em 2 dias*, *ChatGPT Plus - Trial vence em 5 dias*, *Spotify Duo - Mensal*, *Amazon Prime - Anual*) e disponibilize um botão discreto nas configurações/menu para *"Limpar dados de exemplo"*.

---

### 4. Regras de Execução para o Agente
1. Apresente primeiro a **árvore de arquivos** (`lib/models/`, `lib/services/`, `lib/screens/`, `lib/widgets/`, `lib/theme/`) e o conteúdo exato do `pubspec.yaml` (usando apenas pacotes estáveis e compatíveis com Flutter Web + Mobile, como `shared_preferences` e `intl`).
2. Crie cada arquivo **completo**, sem omitir código com comentários como `// TODO` ou `// restante do código aqui`.
3. Garanta que não haja erros de importação, tipagem ou null-safety ao rodar `flutter pub get` e `flutter run`.