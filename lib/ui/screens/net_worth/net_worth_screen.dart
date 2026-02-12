
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../widgets/common/custom_app_bar_v2.dart';
import 'widgets/net_worth_header_card.dart';
import 'widgets/assets_list_view.dart';
import 'widgets/liabilities_list_view.dart';
import 'widgets/net_worth_chart.dart';
import 'widgets/scenario_simulator.dart';
import 'sheets/add_asset_sheet.dart';
import 'sheets/add_liability_sheet.dart';


class NetWorthScreen extends ConsumerStatefulWidget {
  const NetWorthScreen({super.key});

  @override
  ConsumerState<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends ConsumerState<NetWorthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Premium Dark Mode Styling
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBarV2(
        title: 'Net Worth',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.white70),
            onPressed: () {
              // Placeholder for future Ledger/History Log functionality
            },
          ),
        ],
      ),
      body: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: NetWorthHeaderCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: NetWorthChart(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ScenarioSimulator(),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: "Assets"),
                        Tab(text: "Liabilities"),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                const AssetsListView(),
                const LiabilitiesListView(),
              ],
            ),
          ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add Entry'),
        onPressed: () {
          // Check current tab index
          final index = _tabController.index;
          
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              if (index == 0) {
                return const AddAssetSheet();
              } else {
                return const AddLiabilitySheet();
              }
            },
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor, // Clean background for sticky header
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
