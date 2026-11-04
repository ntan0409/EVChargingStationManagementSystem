import React, { useEffect, useState } from "react";
import "./OrderChargingST.css";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import Lottie from "lottie-react";
import L from "leaflet";
import { useNavigate } from "react-router-dom";
import { Wallet, Car, Calendar, BarChart2, HelpCircle, Star, MapPin,User} from "lucide-react";
import { getAuthStatus } from "../../API/Auth";
import { ToastContainer, toast } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import BookingPopup from "../ordercharging/Booking";
import { getAllChargingPost } from "../../API/ChargingPost";
import { getChargingStation, getChargingStationId } from "../../API/Station";
import AdminStationPanel from "../../components/ordercharging/AdminStationPannel"
import ChargingPost from "../../components/ordercharging/ChargingPost"
import MapAnimation from "../animation/MapAnimation.json"
import UserIcon from "../animation/UserIcon.json";

// Icon marker
const markerIcon = new L.Icon({
  iconUrl: "/img/9138039.png",
  iconSize: [40, 40],
  iconAnchor: [20, 40],
});

// Fly to selected station
const FlyToStation = ({ station }) => {
  const map = useMap();
  useEffect(() => {
    if (station?.latitude && station?.longitude) {
      const lat = parseFloat(station.latitude);
      const lng = parseFloat(station.longitude);
      if (!isNaN(lat) && !isNaN(lng)) {
        map.flyTo([lat, lng], 15, { duration: 1.5 });
      }
    }
  }, [station, map]);
  return null;
};
function FlyToUser({ userLocation }) {
  const map = useMap();
  useEffect(() => {
    if (userLocation) {
      console.log("Map fly tới vị trí user:", userLocation);
      map.flyTo([userLocation.lat, userLocation.lng], 15, { duration: 1.5 });
    }
  }, [userLocation, map]);
  return null;
}


const OrderChargingST = () => {
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedStation, setSelectedStation] = useState(null);
  const [stations, setStations] = useState([]);
  const [showBookingPopup, setShowBookingPopup] = useState(false);
  const [user, setUser] = useState(null);
  const [showAdminPopup, setShowAdminPopup] = useState(false);
  const [showPostPopup, setShowPostPopup] = useState(false);
  const [userLocation, setUserLocation] = useState(null);
  const [filterMode, setFilterMode] = useState("all");
  const [stationPosts, setStationPosts] = useState({});
  const [showUserLocation, setShowUserLocation] = useState(false);
  const [showAnimation, setShowAnimation] = useState(true);
   const navigate = useNavigate();

  const userAnimatedIcon = L.divIcon({
    className: "user-lottie-icon",
    html: `<div id="user-animation" style="width: 50px; height: 50px;"></div>`,
    iconSize: [50, 50],
    iconAnchor: [25, 50],
  });
  useEffect(() => {
    if (userLocation) {
      import("lottie-web").then((LottieWeb) => {
        LottieWeb.loadAnimation({
          container: document.getElementById("user-animation"),
          renderer: "svg",
          loop: true,
          autoplay: true,
          animationData: UserIcon,
        });
      });
    }
  }, [userLocation]);
  //locj tieng viet cho laoi xe sp
  const vehicleTypeMap = {
    Car: "Xe hơi",
    Bike: "Xe máy",
  };


  useEffect(() => {
    // Giả sử animation chạy 3 giây
    const timer = setTimeout(() => setShowAnimation(false), 3000);
    return () => clearTimeout(timer);
  }, []);
  
 

  //Tự động lấy vị trí hiện tại
  useEffect(() => {
    const fetchUserLocation = () => {
      if (!navigator.geolocation) {
        console.warn("Trình duyệt không hỗ trợ định vị!");
        setUserLocation({ lat: 10.7769, lng: 106.7009 }); // fallback
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const coords = {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          };
          console.log("Vị trí thực của user:", coords);
          setUserLocation(coords);
        },
        (err) => {
          console.error("Lỗi lấy vị trí:", err.code, err.message);
          toast.warn(
            "Không thể lấy vị trí hiện tại, dùng vị trí mặc định."
          );
          setUserLocation({ lat: 10.7769, lng: 106.7009 }); // fallback
        },
        { enableHighAccuracy: true, timeout: 20000, maximumAge: 10000 }
      );
    };

    fetchUserLocation();
  }, []);



  //Tính khoảng cách giữa 2 điểm (Haversine)
  const getDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371;//ban kinh trai đat
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));//trả về góc trung tâm giữa hai điểm.
  };
  const formatDistance = (km) => {
  if (km < 1) return `${Math.round(km * 1000)} m`;
  return `${km.toFixed(1)} km`;
  };

  //Xác định danh sách trạm hiển thị
  let displayedStations = [...stations];

  if (filterMode === "nearest" && userLocation) {
    displayedStations = [...stations]
      .map((st) => ({
        ...st,
        distance: getDistance(
          userLocation.lat,
          userLocation.lng,
          parseFloat(st.latitude),
          parseFloat(st.longitude)
        ),
      }))
      .filter((st) => st.distance <= 100) // chỉ hiện trạm trong bán kính 
      .sort((a, b) => a.distance - b.distance);

    if (displayedStations.length === 0) {
      toast.info("Không có trạm nào trong bán kính 5km, hiển thị tất cả trạm.");
      displayedStations = [...stations];
    }
  }

  //Đóng popup khi click ngoài
  useEffect(() => {
    const handleClickOutside = (e) => {
      if (
        !e.target.closest(".station-item") &&
        !e.target.closest(".popup-content") &&
        !e.target.closest(".leaflet-container") &&
        !e.target.closest("button")
      ) {
        setSelectedStation(null);
      }
    };
    document.addEventListener("mousedown", handleClickOutside, true);
    return () =>
      document.removeEventListener("mousedown", handleClickOutside, true);
  }, []);

  //Lấy thông tin đăng nhập
  useEffect(() => {
    const fetchUser = async () => {
      try {
        const authStatus = await getAuthStatus();
        if (authStatus.isAuthenticated && authStatus.user) {
          const userData = {
            fullName: authStatus.user.name || "",
            phone: authStatus.user.phone || "",
            email: authStatus.user.email || "",
            carModel: authStatus.user.car || "",
            role:
              authStatus.user.role ||
              authStatus.user.user_role ||
              authStatus.user.user_role_raw ||
              authStatus.role ||"",
          };
          setUser(userData);
        } else setUser(null);
      } catch (err) {
        console.error("Lỗi khi lấy thông tin user:", err);
        setUser(null);
      }
    };
    fetchUser();
  }, []);

  
  const handleToggleLocation = () => {
  if (showUserLocation) {
      setShowUserLocation(false);
      toast.info("Đã tắt hiển thị vị trí của bạn.");
    } else {
      if (!navigator.geolocation) {
        toast.error("Trình duyệt của bạn không hỗ trợ định vị!");
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const coords = {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          };
          setUserLocation(coords);
          setShowUserLocation(true);
          toast.success("Đã bật hiển thị vị trí hiện tại!");
        },
        (err) => {
          console.error("Lỗi khi lấy vị trí:", err);
          toast.error("Không thể lấy vị trí! Hãy bật GPS và thử lại.");
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    }
  };

  // --- Làm mới vị trí (ép cập nhật) ---
  const handleRefreshLocation = () => {
    if (!navigator.geolocation) {
      toast.error("Trình duyệt không hỗ trợ định vị!");
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords = {
          lat: pos.coords.latitude,
          lng: pos.coords.longitude,
        };
        setUserLocation(coords);

        // ép FlyToUser chạy lại
        setShowUserLocation(false);
        setTimeout(() => setShowUserLocation(true), 50);

        toast.success(" Vị trí đã được cập nhật!");
      },
      (err) => {
        console.error("Lỗi khi cập nhật vị trí:", err);
        toast.error("Không thể cập nhật vị trí, hãy bật GPS!");
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );
  };


  //Chọn trạm & load trụ
  const handleSelectStation = async (station) => {
    try {
      const stationDetail = await getChargingStationId(station.id);
      setSelectedStation(stationDetail);
      setStationPosts((prev) => ({
        ...prev,
        [station.id]: (stationDetail.chargingPosts || []).sort((a, b) => a.id - b.id),
      }));
    } catch (err) {
      console.error("Lỗi load trụ sạc:", err);
      setStationPosts((prev) => ({ ...prev, [station.id]: [] }));
    }
  };
  const handleReloadPosts = async (stationId) => {
    try {
      const updatedPosts = await getAllChargingPost(stationId);
      setStationPosts((prev) => ({
        ...prev,
        [stationId]: (updatedPosts || []).sort((a, b) => a.id - b.id),
      }));
    } catch (err) {
      console.error("Lỗi reload posts:", err);
    }
  };

  // Lấy danh sách trạm
  const fetchStations = async () => {
    try {
      setLoading(true);
      const res = await getChargingStation();
      const stationsData = (res.data || [])
        .filter((st) => st.latitude && st.longitude)
        .map((st) => ({ ...st, slots: st.slots ?? 0 }));

      const postsByStation = {};
      for (const st of stationsData) {
        try {
          const detailRes = await getChargingStationId(st.id);
          postsByStation[st.id] =
            detailRes.chargingPosts?.sort((a, b) => a.id - b.id) || [];
        } catch {
          postsByStation[st.id] = [];
        }
      }

      setStations(
        stationsData.sort((a, b) => a.stationName.localeCompare(b.stationName))
      );
      setStationPosts(postsByStation);
    } catch (error) {
      console.error("Lỗi khi lấy danh sách trạm:", error);
      toast.error("Lấy danh sách trạm thất bại!");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStations();
  }, []);

  //lấy danh sách nhân viên



  //  Lọc tên theo từ khóa
  const filteredStations = displayedStations.filter((st) => {
    const term = searchTerm.toLowerCase();
    return (
      st.stationName.toLowerCase().includes(term) ||
      st.location.toLowerCase().includes(term) ||
      st.province.toLowerCase().includes(term)
    );
  });


  if (loading) return <p>Đang tải dữ liệu trạm sạc...</p>;


   if (showAnimation) {
  return (
    <div className="animation-container">
      <Lottie className="my-animation" animationData={MapAnimation} loop={true} />
    </div>
  );
  }

  return (
    <div className="order-container">
      {/* Cột trái */}
      <div className="left-panel">

        <h2>Trạng thái các trạm sạc</h2>

        <div className="search-bar">
          <input
            type="text"
            placeholder="🔍 Tìm theo tên, địa chỉ hoặc tỉnh..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
          <button
            className="btn-admin"
            onClick={() => {
              if (selectedStation?.latitude && selectedStation?.longitude) {
                window.open(
                  `https://www.google.com/maps?q=${selectedStation.latitude},${selectedStation.longitude}`,
                  "_blank"
                );
              } else {
                toast.warn("Vui lòng chọn trạm trước khi mở Google Map!");
              }
            }}
          >
            Google Map
          </button>
        </div>
        <div className="filter-buttons">
          <button
            className={filterMode === "all" ? "active" : ""}
            onClick={() => setFilterMode("all")}
          >
            Tất cả trạm
          </button>
          <button
            className={filterMode === "nearest" ? "active" : ""}
            onClick={() => setFilterMode("nearest")}
          >
            Trạm gần nhất
          </button>
          
          <button className="btn-admin" onClick={handleToggleLocation}>
            {showUserLocation ? " Ẩn vị trí của tôi" : " Vị trí của tôi"}
            </button>

            {showUserLocation && (
              <button className="btn-admin" onClick={handleRefreshLocation}>
                 Cập nhật vị trí
              </button>
            )}
        </div>
        <div className="action-buttons">
          {(!user || user.role === "EVDriver")&&(
          <button className="btn-book" onClick={() => setShowBookingPopup(true)}>
            Đặt lịch sạc
          </button>
          )}
          {/* Chỉ ADMIN mới thấy Admin Panel */}
          {/* {user?.role === "Admin" && (
            <button className="btn-admin" onClick={() => setShowAdminPopup(true)}>
              Quản lý trạm sạc
            </button>
          )} */}

          {/* Admin & Staff đều thấy Quản lý trụ sạc */}
          {/* {(user?.role === "Admin" || user?.role === "Staff") && (
            <button className="btn-admin" onClick={() => setShowPostPopup(true)}>
              Quản lý trụ sạc
            </button>
          )} */}
        </div>

        <div className="station-list">
          {filteredStations.map((st) => (
            <div
              key={st.id}
              
              className={`station-item ${
                selectedStation?.id === st.id ? "active" : ""
              }`}
              onClick={() => handleSelectStation(st)}
            >
              
              
              <h4 className="station-header">
                {st.stationName}
                
                {st.status === "Inactive" && (
                  <span className="inactive"> Ngưng Hoạt Động</span>
                )}
                {st.status === "Active" && (
                  <span className="active"> Đang Hoạt Động</span>
                )}
                {st.status === "Maintenance" && (
                  <span className="maintenance"> Bảo Trì</span>
                )}
              </h4>
              {userLocation && (
                  <span className="distance">
                    {formatDistance(
                      getDistance(
                        userLocation.lat,
                        userLocation.lng,
                        parseFloat(st.latitude),
                        parseFloat(st.longitude)
                      )
                    )}
                  </span>
                )}
              <p>
                Địa Chỉ: {st.location}, {st.province}
              </p>
              <p>Nhân Viên Trạm: {st.operatorName}</p>
              <p>Số Điện Thoại Nhân Viên: {st.operatorPhone}</p>
              


              {/* {selectedStation?.id === st.id && (
                <div className="station-posts">
                  {stationPosts[st.id]?.length > 0 ? (
                    stationPosts[st.id].map((post, index) => (
                      <div
                        key={post.id}
                        className={`post-item status-${post.status}`}
                      >

                        <h5>Trụ {index + 1}</h5>
                        <p>
                          <b>Tên trụ:</b> {post.postName}
                        </p>
                        <p>
                          <b>Cổng sạc:</b> {post.connectorType}
                        </p>
                        <p>
                          <b>Loại xe hỗ trợ:</b> {post.vehicleTypeSupported}
                        </p>
                        <p>
                          <b>Số Cổng Sạc:</b> {post.totalConnectors}
                        </p>
                        <p>
                          <b>Trạng thái:</b>{" "}
                          {post.status === "InActive" && (
                            <span className="inactive"> Inactive</span>
                          )}
                          {post.status === "Available" && (
                            <span className="active"> Active</span>
                          )}
                          {post.status === "Busy" && (
                            <span className="busy"> Busy</span>
                          )}
                          {post.status === "Maintained" && (
                            <span className="maintained"> Maintained</span>
                          )}
                        </p>
                      </div>
                    ))
                  ) : (
                    <p className="no-post">Chưa có trụ sạc</p>
                  )}
                </div>
                
              )} */}
              {/* {selectedStation?.id === st.id && (
                <div className="station-staffs">
                  <h5> Nhân viên phụ trách:</h5>
                  {st.operatorId ? (
                    (() => {
                      const matchedStaff = staffs.find(stf => stf.accountId === st.operatorId);
                      return matchedStaff ? (
                        <p>
                          <b>{matchedStaff.name}</b> – {matchedStaff.phoneNumber || "Không có số điện thoại"}
                        </p>
                      ) : (
                        <p>Không tìm thấy nhân viên với mã {st.operatorId}</p>
                      );
                    })()
                  ) : (
                    <p>Chưa có nhân viên</p>
                  )}
                </div>
              )} */}

            </div>
          ))}
        </div>

        
      </div>

      {/* Cột phải - bản đồ */}
      <div className="right-panel">
        <MapContainer
              center={userLocation
          ? [userLocation.lat, userLocation.lng]
          : [10.7769, 106.7009] // fallback tạm
          }
          zoom={13}
          zoomControl={false}
          style={{ height: "100%", width: "100%", borderRadius: "10px" }}
        >
          <TileLayer
            attribution='&copy; OpenStreetMap contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {filteredStations.map((station) => {
            const lat = parseFloat(station.latitude);
            const lng = parseFloat(station.longitude);
            if (isNaN(lat) || isNaN(lng)) return null;
            return (
              <Marker
                key={station.id}
                position={[lat, lng]}
                icon={markerIcon}
                eventHandlers={{ click: () => handleSelectStation(station) }}
              >
                <Popup className="leaflet-popup-station">
                  <div className="popup-station">
                    <img
                      src={station.imageUrl || "/img/station.jfif"}
                      alt={station.stationName}
                      className="popup-image"
                    />
                    <div className="station-info">
                      <h3>{station.stationName}</h3>
                      <p>
                        {station.status=== "Inactive"&& <span className="inactive"> Ngưng Hoạt Động</span>}
                        {station.status=== "Active"&& <span className="active"> Đang Hoạt Động</span>}
                        {station.status=== "Busy"&& <span className="busy"> Đang Sử Dụng</span>}
                        {station.status=== "Maintenance"&& <span className="maintenance"> Bảo Trì</span>}
                      </p>
                     <h4> Địa chỉ 
                      <button
                          className="btn-popup-map"
                          onClick={() => window.open(
                            `https://www.google.com/maps?q=${station.latitude},${station.longitude}`,
                            "_blank"
                          )}
                        >
                            <MapPin size={10}/> Chỉ đường
                        </button></h4>
                      <p className="station-address">
                        {station.location}, {station.province}
                        
                      </p>
                      <h4>Loại Cổng Sạc</h4>
                        {stationPosts[station.id]?.length > 0 ? (
                          <ul>
                            {Array.from(
                              new Set(
                                stationPosts[station.id].map(p => `${p.connectorType} – ${p.maxPowerKw} kW`)
                              )
                            ).map((info, i) => (
                              <liv key={i}>{info}</liv>
                            ))}
                          </ul>
                        ) : (
                          <p>Chưa có trụ sạc</p>
                        )}

                      <h4>Trụ Sạc</h4>
                        {stationPosts[station.id]?.length > 0 ? (
                          <div>
                            <ul>
                              <liv>
                                Trụ Sạc Xe Hơi Đang Hoạt Động:{" "}
                                {stationPosts[station.id].filter(
                                  p =>
                                    p.status?.toLowerCase() === "available" &&
                                    p.vehicleTypeSupported?.toLowerCase().includes("car")
                                ).length}
                              </liv>
                              <p></p>
                              <liv>
                                Trụ Sạc Xe Máy Đang Hoạt Động:{" "}
                                {stationPosts[station.id].filter(
                                  p =>
                                    p.status?.toLowerCase() === "available" &&
                                    p.vehicleTypeSupported?.toLowerCase().includes("bike")
                                ).length}
                              </liv>
                            </ul>
                          </div>
                        ) : (
                          <p>Chưa có trụ sạc</p>
                        )}

                        <h4>Loại Xe Hổ Trợ:{""}</h4>
                          <div><ul>
                            <liv>
                            {Array.from(
                              new Set(stationPosts[station.id]?.map((p) => vehicleTypeMap[p.vehicleTypeSupported] || p.vehicleTypeSupported))
                            ).join(", ")}
                            </liv>
                            </ul>
                          </div>
                         <h4>Thông tin thêm</h4>
                          <ul className="popup-extra">
                            <liv>Thời gian hoạt động: 24/7</liv>
                            <p></p>
                            <liv>Trạm sạc: Công cộng</liv>
                            <p></p>
                            <liv>
                            Nhân Viên Trạm: {station.operatorName}
                            </liv>
                            <p></p>
                            <liv>
                            Số Điện Thoại Nhân Viên: {station.operatorPhone}
                            </liv>
                          </ul>
                      
                    </div>

                    {(!user || user.role === "EVDriver")&& (
                 <button
                  className="btn-popup-book"
                  onClick={() => {
                    // Kiểm tra user đã login và role
                    if (!user || user.role !== "EVDriver") {
                      toast.error("Bạn cần đăng nhập với tài khoản EVDriver để đặt lịch sạc!");
                      navigate("/login"); // chuyển sang trang login
                      return;
                    }

                    // Kiểm tra profile đầy đủ
                    if (!user.fullName || !user.phone || !user.carModel) {
                      toast.warning("Vui lòng cập nhật đầy đủ hồ sơ trước khi đặt lịch sạc!");
                      return;
                    }

                    // Kiểm tra trạm active
                    if (!station || station.status !== "Active") {
                      toast.warning("Trạm này hiện không hoạt động!");
                      return;
                    }

                    const posts = stationPosts[station.id] || [];
                    const userVehicleType = user.carModel.toLowerCase(); // 'car' hoặc 'bike'

                    // Kiểm tra trạm có trụ phù hợp loại xe
                    const hasSupported = posts.some(
                      (p) =>
                        p.vehicleTypeSupported?.toLowerCase().includes(userVehicleType) &&
                        p.status?.toLowerCase() === "available"
                    );

                    if (!hasSupported) {
                      toast.error("❌ Trạm này không hỗ trợ loại xe của bạn hoặc không còn trụ khả dụng!");
                      return;
                    }

                    setSelectedStation(station);
                    setShowBookingPopup(true);
                  }}
                >
                  Đặt lịch sạc
                </button>
                    )}
                  </div>
                </Popup>
              
              </Marker>

            );
          })}
          {showUserLocation && userLocation && (
                <Marker position={[userLocation.lat, userLocation.lng]} icon={userAnimatedIcon}>
                
              </Marker>
            )}

          {selectedStation && <FlyToStation station={selectedStation} />}
          {showUserLocation && userLocation && <FlyToUser userLocation={userLocation} />}
        </MapContainer>
      </div>
      {/*postpopup */}
      {showPostPopup && (
        <div className="popup-overlay">
          <div className="popup-content large-popup">
            <ChargingPost
              stationId={selectedStation?.id}
              onClose={() => setShowPostPopup(false)}
              onUpdated={() => handleReloadPosts(selectedStation?.id)}
              onReloadPosts={() => handleReloadPosts(selectedStation?.id)}
            />
          </div>
        </div>
      )}

      {/* Popup đặt lịch */}
      {showBookingPopup && (
        <BookingPopup
          stations={stations}
          stationId={selectedStation?.id}
          onClose={() => setShowBookingPopup(false)}
          onAdded={fetchStations}
        />
      )}
      {/* Popup AdminPanel */}
      {showAdminPopup && (
        <div className="popup-overlay">
          <div className="popup-content large-popup">
            <AdminStationPanel
              onClose={() => setShowAdminPopup(false)}
              onUpdated={fetchStations}
              onReloadAdminPannel={() => handleSelectStation(selectedStation?.id)}
            />
          </div>
        </div>
      )}

      <ToastContainer />
    </div>
  );
};

export default OrderChargingST;
