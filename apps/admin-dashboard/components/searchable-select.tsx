"use client";

import { useState } from "react";
import { Check, Search } from "lucide-react";
import { cn } from "@/lib/utils";
import { usePreferences } from "@/components/app-preferences-provider";

export type SearchableOption = { label: string; value: string };

export function SearchableSelect({
  value,
  options,
  onChange,
  placeholder = "Search and select…",
  emptyLabel = "No selection",
  allowEmpty = true,
  className,
}: {
  value: string;
  options: SearchableOption[];
  onChange: (value: string) => void;
  placeholder?: string;
  emptyLabel?: string;
  allowEmpty?: boolean;
  className?: string;
}) {
  const { t } = usePreferences();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const selected = options.find((option) => option.value === value);
  const filtered = options.filter((option) =>
    `${option.label} ${option.value}`
      .toLowerCase()
      .includes(query.trim().toLowerCase()),
  );
  return (
    <div className={cn("relative min-w-[170px]", className)}>
      <button
        type="button"
        className="input flex w-full items-center justify-between gap-2 text-left"
        onClick={() => {
          setOpen((current) => !current);
          setQuery("");
        }}
      >
        <span className={cn("truncate", !selected && "text-zinc-600")}>
          {selected?.label ?? t(placeholder)}
        </span>
        <Search className="h-3.5 w-3.5 shrink-0 text-zinc-600" />
      </button>
      {open && (
        <div className="absolute z-[120] mt-2 w-full min-w-[240px] overflow-hidden rounded-xl border border-white/[.1] bg-[#151518] p-2 shadow-2xl">
          <div className="flex items-center gap-2 rounded-lg border border-white/[.08] bg-black/20 px-2">
            <Search className="h-3.5 w-3.5 text-zinc-600" />
            <input
              autoFocus
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder={t("Type to search…")}
              className="h-9 min-w-0 flex-1 bg-transparent text-xs text-zinc-200 outline-none placeholder:text-zinc-600"
            />
          </div>
          <div className="mt-2 max-h-56 overflow-y-auto">
            {allowEmpty && (
              <button
                type="button"
                className="flex w-full items-center justify-between gap-3 rounded-lg px-2 py-2 text-left text-xs text-zinc-500 hover:bg-white/[.05] hover:text-zinc-200"
                onClick={() => {
                  onChange("");
                  setOpen(false);
                }}
              >
                <span className="truncate">{t(emptyLabel)}</span>
                {!value && <Check className="h-3.5 w-3.5 text-indigo-400" />}
              </button>
            )}
            {filtered.map((option) => (
              <button
                key={option.value}
                type="button"
                className="flex w-full items-center justify-between gap-3 rounded-lg px-2 py-2 text-left text-xs text-zinc-300 hover:bg-white/[.05]"
                onClick={() => {
                  onChange(option.value);
                  setOpen(false);
                }}
              >
                <span className="truncate">{option.label}</span>
                {option.value === value && (
                  <Check className="h-3.5 w-3.5 shrink-0 text-indigo-400" />
                )}
              </button>
            ))}
            {!filtered.length && (
              <div className="px-2 py-6 text-center text-xs text-zinc-600">
                {options.length ? t("No matching options") : t("No options available")}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
