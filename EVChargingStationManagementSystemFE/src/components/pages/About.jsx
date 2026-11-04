import React from 'react';
import './About.css';

const About = () => {
    return (
        <div className="about-container">
            <h1>Giới thiệu về dịch vụ</h1>
            <p>
                Chào mừng bạn đến với dịch vụ <strong>Tìm và Đặt lịch sạc</strong> của chúng tôi!
                Đây là giải pháp tối ưu dành cho các chủ sở hữu xe điện, giúp bạn dễ dàng tìm kiếm
                các trạm sạc gần nhất và đặt lịch sạc một cách nhanh chóng và tiện lợi.
            </p>
            <h2>Tính năng nổi bật</h2>
            <ul>
                <li><strong>Tìm kiếm trạm sạc:</strong> Xác định vị trí các trạm sạc gần bạn chỉ trong vài giây.</li>
                <li><strong>Đặt lịch sạc:</strong> Đặt trước thời gian sạc để đảm bảo trạm sạc luôn sẵn sàng khi bạn cần.</li>
                <li><strong>Thông tin chi tiết:</strong> Cung cấp thông tin về loại cổng sạc, giá cả và tình trạng hoạt động của trạm.</li>
                <li><strong>Hỗ trợ 24/7:</strong> Đội ngũ hỗ trợ luôn sẵn sàng giải đáp mọi thắc mắc của bạn.</li>
            </ul>
            <h2>Mục tiêu của chúng tôi</h2>
            <p>
                Chúng tôi cam kết mang đến cho bạn một trải nghiệm sử dụng dịch vụ tiện lợi, nhanh chóng và đáng tin cậy.
                Với sự phát triển của xe điện, chúng tôi hy vọng sẽ góp phần xây dựng một tương lai xanh và bền vững hơn.
            </p>
            <h2>Liên hệ</h2>
            <p>
                Nếu bạn có bất kỳ câu hỏi hoặc góp ý nào, vui lòng liên hệ với chúng tôi qua email:
                <a href="mailto:support@chargingstation.com"> support@chargingstation.com</a>.
            </p>
        </div>
    );
};

export default About;