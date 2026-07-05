import * as React from "react";
import { cn } from "@/lib/utils";

export const Input = React.forwardRef<
  HTMLInputElement,
  React.ComponentProps<"input">
>(({ className, type, ...props }, ref) => (
  <input
    type={type}
    className={cn(
      "flex h-10 w-full rounded-xl border border-white/[.08] bg-black/25 px-3 py-2 text-sm text-zinc-200 shadow-sm transition placeholder:text-zinc-600 focus-visible:border-indigo-500/50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500/15 disabled:cursor-not-allowed disabled:opacity-50",
      className,
    )}
    ref={ref}
    {...props}
  />
));
Input.displayName = "Input";
