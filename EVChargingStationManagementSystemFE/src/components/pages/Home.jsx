import React, { useState } from "react";
import "./Home.css";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import Orb from "../../effect/Orb";
import { useNavigate } from "react-router-dom";

// Thêm import cho Lottie animation
import Lottie from "lottie-react";
// import chargingAnim from "../animation/Electric vehicle charging animation.json"; // hoặc đổi tên file nếu cần
import chargingStationAnim from "../animation/How does an electric vehicle charging station work_.json";

delete L.Icon.Default.prototype._getIconUrl;

L.Icon.Default.mergeOptions({
    iconRetinaUrl: markerIcon2x,
    iconUrl: markerIcon,
    shadowUrl: markerShadow,
});
// Component để zoom tới station khi chọn
// const FlyToStation = ({ station }) => {
//     const map = useMap();
//     if (station?.coords) {
//         map.flyTo(station.coords, 15); // CHỈNH Ở ĐÂY: bay tới vị trí station
//     }
//     return null;
// };


const Home = () => {

    // const [stations] = useState([
    //     { id: 1, name: "Station A", address: "123 Main St, HCM", slots: 5, coords: [10.78, 106.70] },
    //     { id: 2, name: "Station B", address: "456 Elm St, HCM", slots: 3, coords: [10.775, 106.705] },
    //     { id: 3, name: "Station C", address: "789 Oak St, HCM", slots: 0, coords: [10.77, 106.695] },
    // ]);
    const [selectedStation, setSelectedStation] = useState(null);
    const [bookingTime, setBookingTime] = useState("");
    const [suggestions, setSuggestions] = useState([]);
    const navigate = useNavigate();

    // Giả lập API tìm kiếm trạm sạc
    // const handleSearch = (value) => {
    //     setLocation(value);
    //     const mockStations = [
    //         { id: 1, name: "Station A", address: "123 Main St, HCM", slots: 5, coords: [10.78, 106.70]},
    //         { id: 2, name: "Station B", address: "456 Elm St, HCM", slots: 3 , coords: [10.775, 106.705]},
    //         { id: 3, name: "Station C", address: "789 Oak St, HCM", slots: 0 , coords: [10.77, 106.695]},
    //     ];

    //     if (value) {
    //         const filtered = mockStations.filter(
    //             (s) =>
    //                 s.name.toLowerCase().includes(value.toLowerCase()) ||
    //                 s.address.toLowerCase().includes(value.toLowerCase())
    //         );
    //         setStations(filtered);
    //         setSuggestions(filtered);
    //     } else {
    //         setStations(mockStations);
    //         setSuggestions([]);
    //     }
    // };
    // Khi chọn station
    const handleSelectStation = (station) => {
        setSelectedStation(station);

        setSuggestions([]);
    };



    // Xử lý đặt slot sạc
    const handleBooking = () => {
        if (!selectedStation || !bookingTime) {
            alert("Please select a station and time to book.");
            return;
        }
        alert(`Slot booked at ${selectedStation.name} for ${bookingTime}`);
    };

    return (
        <div className="fullpage-container">
            {/* Hero Section */}
            <section className="section section-hero" id="hero">
                {/* <Orb hue={-20} hoverIntensity={0.25} rotateOnHover={true} /> */}
                <header className="home-hero">
                    <div className="hero-content">
                        <h1>
                            <span className="brand-orange">Quản Lý Trạm Sạc Xe Điện Thông Minh</span>
                            <span className="brand-gradient"> EVOne</span>
                        </h1>
                        <p>Tìm, đặt chỗ và sạc nhanh ở mọi nơi bạn đến.</p>
                        <div className="hero-actions">
                            <button className="btn btn-primary" onClick={() => document.querySelector('#discover')?.scrollIntoView({ behavior: 'smooth' })}>Khám phá ngay</button>
                            {/* <button className="btn btn-ghost" onClick={() => document.querySelector('#search')?.scrollIntoView({ behavior: 'smooth' })}>Tìm trạm sạc</button> */}
                        </div>
                    </div>

                    {/* Thay thế SVG tĩnh bằng Lottie */}
                    <div className="hero-visual" aria-hidden>
                        <div className="glow"></div>

                        <div className="hero-lottie" aria-hidden>
                            <Lottie
                                animationData={chargingStationAnim}
                                loop={true}
                                style={{ width: "520px", height: "360px", maxWidth: "100%" }}
                            />
                        </div>
                    </div>
                </header>

                {/* Navigation Dots */}
                <ul className="nav-dots">
                    <li><button type="button" aria-label="Hero" onClick={() => document.querySelector('#hero')?.scrollIntoView({ behavior: 'smooth' })}></button></li>
                    <li><button type="button" aria-label="Tính năng" onClick={() => document.querySelector('#discover')?.scrollIntoView({ behavior: 'smooth' })}></button></li>
                    <li><button type="button" aria-label="Tìm kiếm" onClick={() => document.querySelector('#search')?.scrollIntoView({ behavior: 'smooth' })}></button></li>
                    {selectedStation && <li><button type="button" aria-label="Đặt chỗ" onClick={() => document.querySelector('#booking')?.scrollIntoView({ behavior: 'smooth' })}></button></li>}
                </ul>
            </section>

            {/* Features Section */}
            <section className="section section-features" id="discover">
                <section className="home-features">
                    <h2 className="section-title">Vì sao chọn <span className="brand-gradient">EVOne</span>?</h2>
                    <div className="features-grid">
                        <div className="feature-card">
                            <div className="icon">🔍</div>
                            <h3>Tìm trạm sạc</h3>
                            <p>Tìm trạm sạc gần bạn theo vị trí hoặc điểm đến, cập nhật theo thời gian thực với độ chính xác cao.</p>
                        </div>
                        <div className="feature-card">
                            <div className="icon">📅</div>
                            <h3>Đặt lịch trước</h3>
                            <p>Đặt chỗ nhanh chóng và tiện lợi để đảm bảo có trạm sạc khi bạn đến nơi.</p>
                        </div>
                        <div className="feature-card">
                            <div className="icon">⚡</div>
                            <h3>Sạc nhanh</h3>
                            <p>Hỗ trợ nhiều chuẩn sạc nhanh với công nghệ tiên tiến, trải nghiệm mượt mà và an toàn.</p>
                        </div>
                        <div className="feature-card">
                            <div className="icon">📊</div>
                            <h3>Xác Thời Gian Thực</h3>
                            <p>Trạng thái trạm sạc, công suất và chi phí hiển thị theo thời gian thực, cập nhật liên tục.</p>
                        </div>
                    </div>
                </section>
            </section>

            {/* About Section (moved below Search) */}
            <section className="section section-about" id="about">
                <section className="home-about">
                    <h2 className="section-title">Về <span className="brand-gradient">EVOne</span></h2>

                    <div className="about-content">
                        <div className="about-text">
                            <p className="about-description">
                                EVOne là nền tảng quản lý và kết nối trạm sạc xe điện hàng đầu Việt Nam,
                                giúp người dùng tìm kiếm, đặt lịch và sạc nhanh một cách thuận tiện và an toàn.
                                Chúng tôi hướng tới việc phổ biến hoá xe điện bằng trải nghiệm trực quan, minh bạch và tin cậy.
                            </p>

                            <div className="about-features">
                                <div className="about-feature-item">
                                    <div className="feature-icon">🗺️</div>
                                    <div className="feature-content">
                                        <h4>Bản đồ thông minh</h4>
                                        <p>Hệ thống bản đồ trực quan với realtime trạng thái trạm sạc</p>
                                    </div>
                                </div>
                                <div className="about-feature-item">
                                    <div className="feature-icon">📱</div>
                                    <div className="feature-content">
                                        <h4>Ứng dụng di động</h4>
                                        <p>Giao diện thân thiện, dễ sử dụng trên mọi thiết bị</p>
                                    </div>
                                </div>
                                <div className="about-feature-item">
                                    <div className="feature-icon">🔌</div>
                                    <div className="feature-content">
                                        <h4>Đa chuẩn sạc</h4>
                                        <p>Hỗ trợ nhiều chuẩn sạc phổ biến và nhà cung cấp uy tín</p>
                                    </div>
                                </div>
                                <div className="about-feature-item">
                                    <div className="feature-icon">💰</div>
                                    <div className="feature-content">
                                        <h4>Thanh toán linh hoạt</h4>
                                        <p>Nhiều phương thức thanh toán an toàn và tiện lợi</p>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="about-visual">
                            <div className="stats-grid">
                                <div className="stat-card">
                                    <div className="stat-icon">⚡</div>
                                    <div className="stat-info">
                                        <span className="stat-value">Hổ Trợ </span>
                                        <span className="stat-label">Trạm sạc</span>
                                        <span className="stat-desc">Trên toàn quốc</span>
                                    </div>
                                </div>
                                <div className="stat-card">
                                    <div className="stat-icon">🚗</div>
                                    <div className="stat-info">
                                        <span className="stat-value">Đảm Bảo</span>
                                        <span className="stat-label">Tin Tưởng Dịch Vụ </span>
                                        <span className="stat-desc">Hỗ Trợ Sạc Xe Điện Của Chúng Tôi</span>
                                    </div>
                                </div>
                                <div className="stat-card">
                                    <div className="stat-icon">📊</div>
                                    <div className="stat-info">
                                        <span className="stat-value">Hệ Thống Thuận Tiện</span>
                                        <span className="stat-label">Hổ Trợ Dịch Vụ Tốt</span>
                                        <span className="stat-desc">Độ tin cậy cao</span>
                                    </div>
                                </div>
                                <div className="stat-card">
                                    <div className="stat-icon">🛠️</div>
                                    <div className="stat-info">
                                        <span className="stat-value">24/7</span>
                                        <span className="stat-label">Hỗ trợ</span>
                                        <span className="stat-desc">Luôn sẵn sàng</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
            </section>



                    {/* Nút mở popup chọn trạm */}
                    <div className="search-bar">
                        <button
                            className="btn btn-primary"
                            onClick={() => {
                                const role = (localStorage.getItem("user_role") || "").toLowerCase();

                                if (role === "admin") {
                                navigate("/admin/admin-map");  
                                } else {
                                navigate("/order-charging");    
                                }
                            }}
                            >
                            Chọn trạm sạc
                        </button>
                    </div>

                    {/* Popup danh sách trạm */}
                    {suggestions.length > 0 && (
                        <div className="popup-overlay">
                            <div className="popup-content">
                                <h3>Danh sách trạm</h3>
                                <ul className="station-select-list">
                                    {suggestions.map((station) => (
                                        <li
                                            key={station.id}
                                            onClick={() => {
                                                handleSelectStation(station);
                                                setSuggestions([]); // đóng popup
                                            }}
                                        >
                                            <b>{station.name}</b> - {station.address}
                                        </li>
                                    ))}
                                </ul>
                                <button
                                    className="btn btn-secondary"
                                    onClick={() => setSuggestions([])} // đóng popup khi bấm hủy
                                >
                                    Đóng
                                </button>
                            </div>
                        </div>
                    )}

                    {/* OpenStreetMap Integration */}
                    
                
      



            {/* Booking Section (conditional) */}
            {selectedStation && (
                <section className="section section-booking" id="booking">
                    <section className="home-booking">
                        <h2 className="section-title">Đặt lịch sạc</h2>
                        <div className="booking-card">
                            <div className="booking-info">
                                <h3>{selectedStation.name}</h3>
                                <p>{selectedStation.address}</p>
                            </div>
                            <div className="booking-action">
                                <input
                                    type="datetime-local"
                                    value={bookingTime}
                                    onChange={(e) => setBookingTime(e.target.value)}
                                />
                                <button className="btn btn-primary" onClick={handleBooking}>Đặt chỗ</button>
                            </div>
                        </div>
                    </section>
                </section>
            )}

            {/* Contact Section */}
            <section className="section section-contact" id="contact">
                <section className="home-contact">
                    <h2 className="section-title">Liên hệ <span className="brand-gradient">EVOne</span></h2>

                    <div className="contact-info-only">
                        <div className="contact-intro">
                            <h3>Kết nối với chúng tôi</h3>
                            <p>Chúng tôi luôn sẵn sàng hỗ trợ và lắng nghe ý kiến của bạn. Hãy liên hệ với EVOne để được tư vấn và hỗ trợ tốt nhất.</p>
                        </div>

                        <div className="contact-methods">
                            <div className="contact-method">
                                <div className="method-icon">📍</div>
                                <div className="method-info">
                                    <h4>Địa chỉ</h4>
                                    <p>123 Innovation Street, Quận 1, TP. Hồ Chí Minh</p>
                                    <span className="method-note">Trụ sở chính - Tầng 15, Tòa nhà EV Tower</span>
                                </div>
                            </div>

                            <div className="contact-method">
                                <div className="method-icon">📞</div>
                                <div className="method-info">
                                    <h4>Hotline</h4>
                                    <p><a href="tel:+84281234567">(+84) 28 1234 567</a></p>
                                    <span className="method-note">Hỗ trợ 24/7 - Khẩn cấp sự cố trạm</span>
                                </div>
                            </div>

                            <div className="contact-method">
                                <div className="method-icon">📧</div>
                                <div className="method-info">
                                    <h4>Email</h4>
                                    <p><a href="mailto:support@evone.vn">support@evone.vn</a></p>
                                    <span className="method-note">Phản hồi trong 2-4 giờ làm việc</span>
                                </div>
                            </div>

                            <div className="contact-method">
                                <div className="method-icon">🕒</div>
                                <div className="method-info">
                                    <h4>Giờ làm việc</h4>
                                    <p>Thứ 2 - Thứ 6: 08:30 - 18:00</p>
                                    <span className="method-note">Thứ 7: 08:30 - 12:00 (Hỗ trợ khẩn cấp 24/7)</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
            </section>
            {/* Floating Social Bar */}
            <div className="floating-social" aria-label="Liên kết mạng xã hội">
                <a className="social-btn" href="https://www.facebook.com/" target="_blank" aria-label="Facebook" title="Facebook" rel="noopener noreferrer">
                    {/* Facebook SVG */}
                    <svg viewBox="0 0 24 24" fill="#1877F2" aria-hidden="true"><path d="M22 12.06C22 6.48 17.52 2 11.94 2S2 6.48 2 12.06c0 5.01 3.66 9.17 8.44 9.94v-7.03H7.9v-2.91h2.54V9.41c0-2.5 1.49-3.88 3.77-3.88 1.09 0 2.24.2 2.24.2v2.46h-1.26c-1.24 0-1.62.77-1.62 1.56v1.87h2.76l-.44 2.91h-2.32V22c4.78-.77 8.44-4.93 8.44-9.94Z" /></svg>
                </a>
                <a className="social-btn" href="https://www.youtube.com/" target="_blank" aria-label="YouTube" title="YouTube" rel="noopener noreferrer">
                    {/* YouTube SVG */}
                    <svg viewBox="0 0 24 24" fill="#FF0000" aria-hidden="true"><path d="M23.5 6.2s-.23-1.65-.95-2.37c-.91-.95-1.93-.96-2.4-1.02C16.58 2.5 12 2.5 12 2.5h-.01s-4.58 0-8.14.31c-.47.06-1.49.07-2.4 1.02C.73 4.55.5 6.2.5 6.2S.27 8.14.27 10.07v1.85c0 1.93.23 3.87.23 3.87s.23 1.65.95 2.37c.91.95 2.11.92 2.64 1.02 1.92.19 8 .31 8 .31s4.58 0 8.14-.31c.47-.06 1.49-.07 2.4-1.02.72-.72.95-2.37.95-2.37s.23-1.94.23-3.87v-1.85c0-1.93-.23-3.87-.23-3.87ZM9.75 13.88V7.94l5.8 2.97-5.8 2.97Z" /></svg>
                </a>
                <a className="social-btn" href="https://www.instagram.com/" target="_blank" aria-label="Instagram" title="Instagram" rel="noopener noreferrer">
                    {/* Instagram SVG */}
                    <svg viewBox="0 0 24 24" fill="#E1306C" aria-hidden="true"><path d="M12 2.16c3.2 0 3.58.01 4.85.07 1.17.05 1.97.24 2.67.52.72.28 1.33.66 1.93 1.27.6.6.98 1.21 1.27 1.93.27.7.47 1.5.52 2.67.06 1.27.07 1.65.07 4.85s-.01 3.58-.07 4.85c-.05 1.17-.24 1.97-.52 2.67-.28.72-.66 1.33-1.27 1.93-.6.6-1.21.98-1.93 1.27-.7.27-1.5.47-2.67.52-1.27.06-1.65.07-4.85.07s-3.58-.01-4.85-.07c-1.17-.05-1.97-.24-2.67-.52a5.49 5.49 0 0 1-1.93-1.27A5.49 5.49 0 0 1 .89 20.2c-.27-.7-.47-1.5-.52-2.67C.31 16.26.3 15.88.3 12.68s.01-3.58.07-4.85c.05-1.17.24-1.97.52-2.67.28-.72.66-1.33 1.27-1.93S3.37 1.25 4.09.97c.7-.27 1.5-.47 2.67-.52C8.03.39 8.41.38 11.61.38c3.2 0 3.58.01 4.85.07Zm0 1.8c-3.15 0-3.52.01-4.76.07-.98.05-1.51.21-1.86.34-.47.18-.81.39-1.17.74-.35.36-.56.7-.74 1.17-.13.35-.29.88-.34 1.86-.06 1.24-.07 1.61-.07 4.76s.01 3.52.07 4.76c.05.98.21 1.51.34 1.86.18.47.39.81.74 1.17.36.35.7.56 1.17.74.35.13.88.29 1.86.34 1.24.06 1.61.07 4.76.07s3.52-.01 4.76-.07c.98-.05 1.51-.21 1.86-.34.47-.18.81-.39 1.17-.74.35-.36.56-.7.74-1.17.13-.35.29-.88.34-1.86.06-1.24.07-1.61.07-4.76s-.01-3.52-.07-4.76c-.05-.98-.21-1.51-.34-1.86a3.62 3.62 0 0 0-.74-1.17 3.62 3.62 0 0 0-1.17-.74c-.35-.13-.88-.29-1.86-.34-1.24-.06-1.61-.07-4.76-.07Zm0 3.13a6.91 6.91 0 1 1 0 13.82 6.91 6.91 0 0 1 0-13.82Zm0 1.8a5.11 5.11 0 1 0 0 10.22 5.11 5.11 0 0 0 0-10.22Zm6.99-2.3a1.62 1.62 0 1 1-3.24 0 1.62 1.62 0 0 1 3.24 0Z" /></svg>
                </a>
                <a className="social-btn" href="https://shopee.vn/" target="_blank" aria-label="Shopee" title="Shopee" rel="noopener noreferrer">
                    {/* Shopee SVG */}
                    <svg viewBox="0 0 24 24" fill="#EE4D2D" aria-hidden="true"><path d="M17.7 8.5c-.33-2.74-2.9-4.85-5.7-4.85S6.63 5.76 6.3 8.5H4v10.06c0 .79.64 1.44 1.43 1.44h13.14c.79 0 1.43-.65 1.43-1.44V8.5h-2.3Zm-8.6 0c.3-1.76 1.87-3.05 3.9-3.05 2.03 0 3.6 1.29 3.9 3.05H9.1Zm1.5 9.33c-1.56 0-2.7-.83-2.7-2.05 0-.95.61-1.6 1.9-1.94l1.56-.42c.72-.19.96-.4.96-.8 0-.57-.56-.95-1.4-.95-.88 0-1.5.41-1.64 1.05H7.75c.1-1.47 1.37-2.43 3.3-2.43 1.86 0 3.2 1 3.2 2.4 0 1.02-.56 1.63-1.86 1.98l-1.5.4c-.76.2-1.06.43-1.06.86 0 .53.56.9 1.37.9.93 0 1.56-.4 1.72-1.08h1.24c-.18 1.55-1.47 2.24-3.1 2.24Z" /></svg>
                </a>
            </div>

            {/* Floating Action Button */}
            <button type="button" className="floating-action" aria-label="Hỗ trợ" onClick={() => document.querySelector('#contact')?.scrollIntoView({ behavior: 'smooth' })}>
                ?
            </button>
        </div>
    );
};

export default Home;
