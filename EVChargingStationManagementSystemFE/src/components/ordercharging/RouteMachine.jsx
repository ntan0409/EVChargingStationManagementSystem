import { useEffect, useRef } from "react";
import L from "leaflet";
import "leaflet-routing-machine";
import "leaflet-routing-machine/dist/leaflet-routing-machine.css";

const RoutingMachine = ({ map, userLocation, station }) => {
  const routingRef = useRef(null);

  useEffect(() => {
    if (!map || !userLocation || !station) return;

    // Xóa route cũ nếu có
    if (routingRef.current) {
      map.removeControl(routingRef.current);
    }

    // Tạo route
    const control = L.Routing.control({
      waypoints: [
        L.latLng(userLocation.lat, userLocation.lng),
        L.latLng(parseFloat(station.latitude), parseFloat(station.longitude)),
      ],
      router: L.Routing.osrmv1({
        serviceUrl: "https://router.project-osrm.org/route/v1",
      }),
      lineOptions: { styles: [{ color: "#007BFF", weight: 6 }] },
      routeWhileDragging: false,
      addWaypoints: false,
      draggableWaypoints: false,
      fitSelectedRoutes: true,
      showAlternatives: false,
      createMarker: (i, wp) => {
        return L.marker(wp.latLng, {
          icon: L.icon({
            iconUrl: i === 0 ? "/img/user-marker.png" : "/img/station-marker.png",
            iconSize: [35, 35],
            iconAnchor: [17, 35],
          }),
        });
      },
    }).addTo(map);

    routingRef.current = control;

    return () => {
      if (routingRef.current) map.removeControl(routingRef.current);
    };
  }, [map, userLocation, station]);

  return null;
};

export default RoutingMachine;
