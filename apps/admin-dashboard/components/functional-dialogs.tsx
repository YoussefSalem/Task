"use client";
import { useEffect, useState } from "react";
import { AlertTriangle, Check, Loader2, MoreHorizontal, Search, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { usePreferences } from "@/components/app-preferences-provider";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export interface FormField {
  name: string;
  label: string;
  type?:
    | "text"
    | "email"
    | "tel"
    | "number"
    | "datetime-local"
    | "select"
    | "textarea"
    | "multiselect";
  placeholder?: string;
  required?: boolean;
  options?: Array<{ label: string; value: string }>;
  min?: number;
  showWhen?: { field: string; value: string };
}
export function FormDialog({
  open,
  title,
  description,
  fields,
  initial = {},
  submitLabel = "Save changes",
  onClose,
  onSubmit,
}: {
  open: boolean;
  title: string;
  description?: string;
  fields: FormField[];
  initial?: Record<string, string | number>;
  submitLabel?: string;
  onClose: () => void;
  onSubmit: (values: Record<string, string>) => unknown;
}) {
  const { t } = usePreferences();
  const [values, setValues] = useState<Record<string, string>>({});
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitError, setSubmitError] = useState("");
  const [saving, setSaving] = useState(false);
  const initialSignature = JSON.stringify(initial);
  useEffect(() => {
    if (open) {
      setErrors({});
      setSubmitError("");
      setValues(
        Object.fromEntries(
          Object.entries(
            JSON.parse(initialSignature) as Record<string, string | number>,
          ).map(([k, v]) => [k, String(v ?? "")]),
        ),
      );
    }
  }, [open, initialSignature]);
  if (!open) return null;
  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const next: Record<string, string> = {};
    fields.forEach((f) => {
      if (f.showWhen && values[f.showWhen.field] !== f.showWhen.value) return;
      if (f.required && !values[f.name]?.trim())
        next[f.name] = `${t(f.label)} ${t("is required")}`;
      if (
        f.type === "email" &&
        values[f.name] &&
        !/^\S+@\S+\.\S+$/.test(values[f.name])
      )
        next[f.name] = t("Enter a valid email");
      if (
        f.type === "number" &&
        f.min !== undefined &&
        Number(values[f.name]) < f.min
      )
        next[f.name] = `Minimum is ${f.min}`;
    });
    setErrors(next);
    if (Object.keys(next).length) return;
    setSaving(true);
    await new Promise((r) => setTimeout(r, 180));
    try {
      await onSubmit(values);
      onClose();
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : "Unable to save changes");
    } finally {
      setSaving(false);
    }
  };
  return (
    <div
      className="fixed inset-0 z-[100] grid place-items-center bg-black/70 p-4 backdrop-blur-sm"
      onMouseDown={onClose}
    >
      <form
        onSubmit={submit}
        onMouseDown={(e) => e.stopPropagation()}
        className="w-full max-w-lg overflow-hidden rounded-2xl border border-white/[.1] bg-[#141417] shadow-[0_30px_120px_rgba(0,0,0,.65)]"
      >
        <div className="flex items-start justify-between border-b border-white/[.07] p-5">
          <div>
            <h2 className="text-base font-semibold">{t(title)}</h2>
            {description && (
              <p className="mt-1 text-xs text-zinc-500">{t(description)}</p>
            )}
          </div>
          <Button type="button" variant="ghost" size="icon" onClick={onClose}>
            <X />
          </Button>
        </div>
        <div className="grid max-h-[65vh] gap-4 overflow-y-auto p-5 sm:grid-cols-2">
          {fields.filter((field) => !field.showWhen || values[field.showWhen.field] === field.showWhen.value).map((field) => (
            <label
              key={field.name}
              className={
                field.type === "textarea" || field.type === "multiselect"
                  ? "sm:col-span-2"
                  : ""
              }
            >
              <span className="mb-2 block text-[11px] font-medium text-zinc-400">
                {t(field.label)}
                {field.required && <span className="text-red-400"> *</span>}
              </span>
              {field.type === "select" ? (
                <SearchableSelectField
                  field={field}
                  value={values[field.name] ?? ""}
                  onChange={(value) =>
                    setValues((v) => ({ ...v, [field.name]: value }))
                  }
                />
              ) : field.type === "textarea" ? (
                <textarea
                  value={values[field.name] ?? ""}
                  onChange={(e) =>
                    setValues((v) => ({ ...v, [field.name]: e.target.value }))
                  }
                  placeholder={field.placeholder}
                  className="input min-h-24 w-full resize-none py-3"
                />
              ) : (
                <Input
                  type={field.type ?? "text"}
                  min={field.min}
                  value={values[field.name] ?? ""}
                  onChange={(e) =>
                    setValues((v) => ({ ...v, [field.name]: e.target.value }))
                  }
                  placeholder={field.placeholder}
                />
              )}{" "}
              {errors[field.name] && (
                <span className="mt-1.5 block text-[10px] text-red-400">
                  {errors[field.name]}
                </span>
              )}
            </label>
          ))}
        </div>
        {submitError && <div role="alert" className="mx-5 mb-4 rounded-xl border border-red-500/20 bg-red-500/10 p-3 text-xs text-red-300">{submitError}</div>}
        <div className="flex justify-end gap-2 border-t border-white/[.07] p-4">
          <Button type="button" variant="secondary" onClick={onClose}>
            {t("Cancel")}
          </Button>
          <Button type="submit" disabled={saving}>
            {saving && <Loader2 className="animate-spin" />}
            {t(submitLabel)}
          </Button>
        </div>
      </form>
    </div>
  );
}

function SearchableSelectField({
  field,
  value,
  onChange,
}: {
  field: FormField;
  value: string;
  onChange: (value: string) => void;
}) {
  const { t } = usePreferences();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const options = field.options ?? [];
  const selected = options.find((option) => option.value === value);
  const filtered = options.filter((option) =>
    `${option.label} ${option.value}`.toLowerCase().includes(query.toLowerCase()),
  );
  return (
    <div className="relative">
      <button
        type="button"
        className="input flex w-full items-center justify-between text-left"
        onClick={() => {
          setOpen((current) => !current);
          setQuery("");
        }}
      >
        <span className={selected ? "truncate" : "truncate text-zinc-600"}>
          {selected?.label ?? t(field.placeholder ?? "Search and select…")}
        </span>
        <Search className="h-3.5 w-3.5 text-zinc-600" />
      </button>
      {open && (
        <div className="absolute z-[130] mt-2 w-full overflow-hidden rounded-xl border border-white/[.1] bg-[#151518] p-2 shadow-2xl">
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
            {!field.required && (
              <button
                type="button"
                className="flex w-full items-center justify-between rounded-lg px-2 py-2 text-left text-xs text-zinc-500 hover:bg-white/[.05] hover:text-zinc-200"
                onClick={() => {
                  onChange("");
                  setOpen(false);
                }}
              >
                {t("No selection")}
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

export function ConfirmDialog({
  open,
  title,
  description,
  confirmLabel = "Delete",
  tone = "danger",
  onClose,
  onConfirm,
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel?: string;
  tone?: "danger" | "primary";
  onClose: () => void;
  onConfirm: () => unknown | Promise<unknown>;
}) {
  const [saving,setSaving]=useState(false);
  const [error,setError]=useState("");
  useEffect(()=>{if(open)setError("")},[open]);
  if (!open) return null;
  return (
    <div
      className="fixed inset-0 z-[110] grid place-items-center bg-black/70 p-4 backdrop-blur-sm"
      onMouseDown={onClose}
    >
      <div
        onMouseDown={(e) => e.stopPropagation()}
        className="w-full max-w-sm rounded-2xl border border-white/[.1] bg-[#151518] p-5 shadow-2xl"
      >
        <span className="grid h-11 w-11 place-items-center rounded-xl bg-red-500/10 text-red-400">
          <AlertTriangle className="h-5 w-5" />
        </span>
        <h2 className="mt-4 text-base font-semibold">{title}</h2>
        <p className="mt-2 text-xs leading-5 text-zinc-500">{description}</p>
        {error && (
          <p className="mt-4 rounded-xl border border-red-500/25 bg-red-500/10 p-3 text-xs leading-5 text-red-200">
            {error}
          </p>
        )}
        <div className="mt-6 flex justify-end gap-2">
          <Button variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button
            variant={tone === "danger" ? "destructive" : "default"}
            disabled={saving}
            onClick={async() => {
              setSaving(true);
              setError("");
              try{await onConfirm();onClose()}catch(reason){const message=reason instanceof Error?reason.message:"The server could not complete this action";console.error("[Task Admin] Confirmation action failed",reason);setError(message)}finally{setSaving(false)}
            }}
          >
            {saving&&<Loader2 className="animate-spin"/>}
            {confirmLabel}
          </Button>
        </div>
      </div>
    </div>
  );
}

export interface RowAction {
  label: string;
  onClick: () => unknown | Promise<unknown>;
  danger?: boolean;
  separator?: boolean;
}
export function RowActions({
  actions,
  label = "Open actions",
}: {
  actions: RowAction[];
  label?: string;
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button aria-label={label} variant="ghost" size="icon">
          <MoreHorizontal />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {actions.map((a, i) => (
          <span key={`${a.label}-${i}`}>
            {a.separator && <DropdownMenuSeparator />}
            <DropdownMenuItem
              onSelect={() => {
                void Promise.resolve(a.onClick()).catch((reason) =>
                  console.error("[Task Admin] Row action failed", reason),
                );
              }}
              className={a.danger ? "text-red-400 focus:text-red-300" : ""}
            >
              {a.label}
            </DropdownMenuItem>
          </span>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
