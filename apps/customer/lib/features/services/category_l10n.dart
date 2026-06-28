import 'package:customer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:task_design/task_design.dart';
import 'package:task_domain/task_domain.dart';

/// Localized display name for a [JobCategory]. The domain enum carries an
/// English `displayLabel` for persistence/debugging; this is the single place
/// the UI turns a category into user-facing copy in the active locale.
String categoryLabel(JobCategory c, AppLocalizations l) => switch (c) {
      JobCategory.plumbing => l.plumber,
      JobCategory.electrical => l.electrician,
      JobCategory.ac => l.acMaintenance,
      JobCategory.cleaning => l.cleaning,
      JobCategory.carpentry => l.carpenter,
      JobCategory.painting => l.catPainter,
      JobCategory.satelliteInstallation => l.catSatellite,
      JobCategory.smartHome => l.catSmartHome,
      JobCategory.tilesHandyman => l.catTilesHandyman,
      JobCategory.masonStones => l.masonAndDecorationStones,
      JobCategory.plaster => l.catPlaster,
      JobCategory.smith => l.catSmith,
      JobCategory.parquet => l.catParquet,
      JobCategory.gypsumWorks => l.catGypsumWorks,
      JobCategory.gypsumBoard => l.catGypsumBoard,
      JobCategory.marbleGranite => l.catMarbleGranite,
      JobCategory.alumetal => l.catAlumetal,
      JobCategory.glassCecurit => l.catGlassCecurit,
      JobCategory.curtainsUpholstery => l.catCurtainsUpholstery,
      JobCategory.woodPainter => l.catWoodPainter,
      JobCategory.movingServices => l.catMovingServices,
      JobCategory.puCornices => l.catPuCornices,
      JobCategory.materialWinch => l.catMaterialWinch,
      JobCategory.appliancesMaintenance => l.catAppliancesMaintenance,
      JobCategory.swimmingPool => l.catSwimmingPool,
      JobCategory.pestControl => l.catPestControl,
    };

/// Localized label + accent for a technician trust [TechnicianTier], shown as a
/// chip on directory cards.
extension TechnicianTierUi on TechnicianTier {
  String label(AppLocalizations l) => switch (this) {
        TechnicianTier.bronze => l.tierBronze,
        TechnicianTier.silver => l.tierSilver,
        TechnicianTier.gold => l.tierGold,
        TechnicianTier.platinum => l.tierPlatinum,
      };

  Color get tint => switch (this) {
        TechnicianTier.bronze => const Color(0xFFB45309),
        TechnicianTier.silver => AppColors.textSecondary,
        TechnicianTier.gold => AppColors.warning,
        TechnicianTier.platinum => AppColors.primary,
      };
}

/// Localized label for a [JobStatus], used on status pills.
String jobStatusLabel(JobStatus s, AppLocalizations l) => switch (s) {
      JobStatus.searching => l.statusSearching,
      JobStatus.pendingScheduled => l.statusPendingScheduled,
      JobStatus.biddingActive => l.statusBiddingActive,
      JobStatus.accepted => l.statusAccepted,
      JobStatus.enRoute => l.statusEnRoute,
      JobStatus.inProgress => l.statusInProgress,
      JobStatus.pausedForApproval => l.statusPausedForApproval,
      JobStatus.completed => l.statusCompleted,
      JobStatus.disputed => l.statusDisputed,
      JobStatus.cancelled => l.statusCancelled,
    };
