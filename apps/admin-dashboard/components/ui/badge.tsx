import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva(
  "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary/15 text-indigo-300",
        secondary: "border-white/[.08] bg-white/[.05] text-zinc-400",
        success: "border-emerald-500/20 bg-emerald-500/10 text-emerald-400",
        warning: "border-amber-500/20 bg-amber-500/10 text-amber-400",
        destructive: "border-red-500/20 bg-red-500/10 text-red-400",
        outline: "border-white/[.1] text-zinc-400",
      },
    },
    defaultVariants: { variant: "default" },
  },
);
export interface BadgeProps
  extends
    React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}
export function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}
export { badgeVariants };
