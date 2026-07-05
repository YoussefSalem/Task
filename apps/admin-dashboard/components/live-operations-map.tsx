"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { AlertTriangle, LocateFixed, MapPinned } from "lucide-react";
import type { Job, Provider, ProviderLocation } from "@/lib/types";
import { Badge } from "@/components/ui/badge";
import { usePreferences } from "@/components/app-preferences-provider";

export function LiveOperationsMap({
  locations,
  providers,
  jobs,
  selectedJob,
}: {
  locations: ProviderLocation[];
  providers: Provider[];
  jobs: Job[];
  selectedJob?: Job | null;
}) {
  const { theme } = usePreferences();
  const host = useRef<HTMLDivElement>(null);
  const mapRef = useRef<google.maps.Map | null>(null);
  const [state, setState] = useState<
    "loading" | "ready" | "fallback" | "error"
  >("loading");
  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  const activeJobs = useMemo(
    () =>
      jobs.filter(
        (j) => !["Completed", "Cancelled", "Refunded"].includes(j.status),
      ),
    [jobs],
  );
  useEffect(() => {
    if (!apiKey) {
      setState("fallback");
      return;
    }
    let cancelled = false;
    const init = () => {
      if (cancelled || !host.current) return;
      try {
        const darkMap =
          theme === "dark" ||
          (theme === "system" &&
            window.matchMedia("(prefers-color-scheme: dark)").matches);
        const map = new google.maps.Map(host.current, {
          center: { lat: 30.0444, lng: 31.2357 },
          zoom: 11,
          disableDefaultUI: true,
          zoomControl: true,
          styles: darkMap
            ? [
                { elementType: "geometry", stylers: [{ color: "#15171b" }] },
                {
                  elementType: "labels.text.fill",
                  stylers: [{ color: "#8b8d93" }],
                },
                {
                  elementType: "labels.text.stroke",
                  stylers: [{ color: "#15171b" }],
                },
                {
                  featureType: "road",
                  elementType: "geometry",
                  stylers: [{ color: "#272a31" }],
                },
                {
                  featureType: "water",
                  elementType: "geometry",
                  stylers: [{ color: "#0c2432" }],
                },
              ]
            : [],
        });
        mapRef.current = map;
        const bounds = new google.maps.LatLngBounds();
        locations.forEach((loc) => {
          const provider = providers.find((p) => p.id === loc.providerId);
          const position = { lat: loc.lat, lng: loc.lng };
          new google.maps.Marker({
            map,
            position,
            title: provider?.name ?? loc.providerId,
            icon: {
              path: google.maps.SymbolPath.CIRCLE,
              scale: 8,
              fillColor:
                loc.status === "Available"
                  ? "#22c55e"
                  : loc.status === "Busy"
                    ? "#6366f1"
                    : "#71717a",
              fillOpacity: 1,
              strokeColor: "#ffffff",
              strokeWeight: 2,
            },
          });
          bounds.extend(position);
        });
        activeJobs.forEach((job) => {
          if (job.gps) {
            new google.maps.Marker({
              map,
              position: job.gps,
              title: `${job.id} · ${job.customer}`,
              label: { text: "J", color: "#fff", fontSize: "10px" },
              icon: {
                path: google.maps.SymbolPath.CIRCLE,
                scale: 10,
                fillColor:
                  job.priority === "Emergency" || job.status === "Delayed"
                    ? "#ef4444"
                    : "#f59e0b",
                fillOpacity: 1,
                strokeColor: "#fff",
                strokeWeight: 2,
              },
            });
            bounds.extend(job.gps);
          }
        });
        if (!bounds.isEmpty()) map.fitBounds(bounds, 80);
        setState("ready");
      } catch {
        setState("error");
      }
    };
    if (window.google?.maps) {
      init();
      return () => {
        cancelled = true;
      };
    }
    const id = "task-google-maps";
    let script = document.getElementById(id) as HTMLScriptElement | null;
    if (!script) {
      script = document.createElement("script");
      script.id = id;
      script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&v=weekly`;
      script.async = true;
      script.defer = true;
      document.head.appendChild(script);
    }
    script.addEventListener("load", init);
    script.addEventListener("error", () => setState("error"));
    return () => {
      cancelled = true;
      script?.removeEventListener("load", init);
    };
  }, [apiKey, activeJobs, locations, providers, theme]);
  useEffect(() => {
    if (!selectedJob || !mapRef.current) return;
    const customer = selectedJob.gps;
    const provider = locations.find(
      (l) => l.providerId === selectedJob.providerId,
    );
    if (!customer || !provider) return;
    const path = [{ lat: provider.lat, lng: provider.lng }, customer];
    new google.maps.Polyline({
      map: mapRef.current,
      path,
      strokeColor: "#818cf8",
      strokeOpacity: 0.9,
      strokeWeight: 4,
    });
    const bounds = new google.maps.LatLngBounds();
    path.forEach((p) => bounds.extend(p));
    mapRef.current.fitBounds(bounds, 70);
  }, [selectedJob, locations]);
  return (
    <div className="panel relative min-h-[430px] overflow-hidden">
      <div ref={host} className="absolute inset-0" />
      {state !== "ready" && (
        <div className="grid-noise absolute inset-0 grid place-items-center bg-[#0e1115] p-10 text-center">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_60%_40%,rgba(99,102,241,.15),transparent_35%)]" />
          <div className="relative max-w-md"><MapPinned className="mx-auto h-8 w-8 text-indigo-400"/><h3 className="mt-3 text-sm font-semibold">{state==="error"?"Google Maps could not load":"Google Maps configuration required"}</h3><p className="mt-2 text-xs leading-5 text-zinc-500">{state==="error"?"Check the browser key restrictions and Maps JavaScript API status.":"Set NEXT_PUBLIC_GOOGLE_MAPS_API_KEY to render live database locations. No synthetic locations are displayed."}</p><div className="mt-4 text-[10px] text-zinc-600">{locations.length} stored provider locations · {activeJobs.filter((job)=>job.gps).length}/{activeJobs.length} jobs with GPS</div></div>
        </div>
      )}
      <div className="absolute left-4 top-4 rounded-xl border border-white/[.08] bg-black/60 p-3 backdrop-blur">
        <div className="flex items-center gap-2 text-xs font-semibold">
          <MapPinned className="h-4 w-4 text-indigo-400" />
          Live coverage
        </div>
        <div className="mt-1 text-[10px] text-zinc-400">
          {locations.filter((x) => x.status !== "Offline").length} providers ·{" "}
          {activeJobs.filter((job) => job.gps).length}/{activeJobs.length} jobs with GPS
        </div>
      </div>
      <div className="absolute right-4 top-4">
        <Badge
          variant={
            state === "ready"
              ? "success"
              : state === "error"
                ? "destructive"
                : "warning"
          }
        >
          {state === "ready"
            ? "Google Maps live"
            : state === "fallback"
              ? "Maps key required"
              : state === "error"
                ? "Map failed"
                : "Loading map"}
        </Badge>
      </div>
      {selectedJob && (
        <div className="absolute bottom-4 left-4 right-4 flex items-center gap-3 rounded-xl border border-white/[.08] bg-black/70 p-3 text-xs backdrop-blur">
          <LocateFixed className="h-4 w-4 text-indigo-400" />
          <span className="flex-1">
            <b>{selectedJob.id}</b>
            <span className="ml-2 text-zinc-400">
              Route preview · {selectedJob.provider} → {selectedJob.customer}
            </span>
          </span>
          {selectedJob.status === "Delayed" && (
            <AlertTriangle className="h-4 w-4 text-amber-400" />
          )}
        </div>
      )}
    </div>
  );
}
