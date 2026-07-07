"use client";

import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/components/auth-provider";
import {
  environmentBadges,
  type EnvironmentBadgeTone,
} from "@/lib/firebase/read-only-mode";

const TONE_VARIANT: Record<EnvironmentBadgeTone, "warning" | "secondary" | "destructive"> = {
  demo: "warning",
  readonly: "secondary",
  disabled: "destructive",
};

/**
 * Shows the current data-environment badges in the dashboard shell:
 * - "Demo Data" for demo actors
 * - "Production Read-only" + "Production Write Disabled" for production actors
 *   while the dashboard is in read-only mode (Phase D.1).
 * The badge decision lives in the pure environmentBadges() helper so it is
 * unit-tested independently of this component.
 */
export function EnvironmentBadges() {
  const { user } = useAuth();
  if (!user) return null;
  const badges = environmentBadges(user.isDemoUser);
  if (badges.length === 0) return null;
  return (
    <div className="flex flex-wrap items-center gap-1.5" aria-label="Data environment status">
      {badges.map((badge) => (
        <Badge key={badge.label} variant={TONE_VARIANT[badge.tone]}>
          {badge.label}
        </Badge>
      ))}
    </div>
  );
}
