import 'package:material_ui/material_ui.dart';

import '../models/subscription.dart';
import '../services/subscription_repository.dart';
import '../widgets/filter_bar.dart';
import '../widgets/subscription_tile.dart';
import '../widgets/summary_cards.dart';
import '../widgets/urgent_alerts.dart';
import 'subscription_detail_screen.dart';
import 'subscription_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.repository});

  final SubscriptionRepository repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();

  SubscriptionRepository get repo => widget.repository;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Subscription? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionFormScreen(
          repository: repo,
          existing: existing,
        ),
      ),
    );
  }

  Future<void> _openDetail(Subscription sub) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubscriptionDetailScreen(
          repository: repo,
          subscriptionId: sub.id,
        ),
      ),
    );
  }

  void _cycleTheme() {
    final next = switch (repo.themeMode) {
      'light' => 'dark',
      'dark' => 'system',
      _ => 'light',
    };
    repo.setThemeMode(next);
  }

  IconData get _themeIcon {
    return switch (repo.themeMode) {
      'light' => Icons.light_mode_outlined,
      'dark' => Icons.dark_mode_outlined,
      _ => Icons.brightness_auto_outlined,
    };
  }

  Future<void> _showMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Nova assinatura'),
                onTap: () => Navigator.pop(ctx, 'new'),
              ),
              if (repo.hasDemoData)
                ListTile(
                  leading: const Icon(Icons.delete_sweep_outlined),
                  title: const Text('Limpar dados de exemplo'),
                  subtitle: const Text(
                    'Remove apenas os 4 itens mock iniciais',
                  ),
                  onTap: () => Navigator.pop(ctx, 'clear_demo'),
                ),
              ListTile(
                leading: Icon(_themeIcon),
                title: Text('Tema: ${_themeLabel(repo.themeMode)}'),
                onTap: () => Navigator.pop(ctx, 'theme'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    switch (action) {
      case 'new':
        await _openForm();
      case 'clear_demo':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Limpar dados de exemplo?'),
            content: const Text(
              'Os 4 itens de demonstração serão removidos. '
              'Suas assinaturas reais permanecem.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Limpar'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await repo.clearDemoData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dados de exemplo removidos.')),
            );
          }
        }
      case 'theme':
        _cycleTheme();
    }
  }

  String _themeLabel(String mode) {
    return switch (mode) {
      'light' => 'Claro',
      'dark' => 'Escuro',
      _ => 'Sistema',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final filtered = repo.filteredItems;
        final urgent = repo.filter == SubscriptionFilter.canceled
            ? <Subscription>[]
            : repo.urgentItems;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Radar Assinaturas'),
            actions: [
              IconButton(
                tooltip: 'Alternar tema',
                onPressed: _cycleTheme,
                icon: Icon(_themeIcon),
              ),
              IconButton(
                tooltip: 'Menu',
                onPressed: _showMenu,
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nova Assinatura'),
          ),
          body: RefreshIndicator(
            onRefresh: () async => repo.init(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                SummaryCards(
                  monthly: repo.monthlySpend,
                  yearly: repo.yearlyProjection,
                  atRisk: repo.atRiskAmount,
                  savings: repo.savingsFromCancellations,
                ),
                if (urgent.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  UrgentAlerts(
                    items: urgent,
                    onTap: _openDetail,
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: repo.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar por serviço ou cartão…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              repo.setSearchQuery('');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                FilterBar(
                  selected: repo.filter,
                  onChanged: repo.setFilter,
                ),
                const SizedBox(height: 16),
                Text(
                  'Assinaturas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma assinatura neste filtro.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map(
                    (sub) => SubscriptionTile(
                      subscription: sub,
                      onTap: () => _openDetail(sub),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
