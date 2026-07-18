import 'package:shadcn_flutter/shadcn_flutter.dart';

class DowngradeDensity extends StatelessWidget {
  const DowngradeDensity({super.key, required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Theme(
      data: t.copyWith(
        density: () {
          switch (t.density) {
            case Density.spaciousDensity:
              return Density.defaultDensity;
            case Density.compactDensity:
              return Density.compactDensity;
            case Density.defaultDensity:
              return Density.reducedDensity;
            case Density.reducedDensity:
              return Density.compactDensity;
            default:
              return Density.defaultDensity;
          }
        },
      ),
      child: child,
    );
  }
}

class UpgradeDensity extends StatelessWidget {
  const UpgradeDensity({super.key, required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Theme(
      data: t.copyWith(
        density: () {
          switch (t.density) {
            case Density.spaciousDensity:
              return Density.spaciousDensity;
            case Density.compactDensity:
              return Density.spaciousDensity;
            case Density.defaultDensity:
              return Density.compactDensity;
            case Density.reducedDensity:
              return Density.defaultDensity;
            default:
              return Density.defaultDensity;
          }
        },
      ),
      child: child,
    );
  }
}
