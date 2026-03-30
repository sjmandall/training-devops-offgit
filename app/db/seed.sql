USE trainingdb;

INSERT INTO users (name, email) VALUES
('Amit Sharma', 'amit@example.com'),
('Neha Verma', 'neha@example.com');

INSERT INTO tickets (user_id, title, status, description) VALUES
(1, 'Laptop issue', 'open', 'Laptop is not booting properly'),
(2, 'VPN access', 'in_progress', 'Need VPN access for remote work'),
(1, 'Email setup', 'closed', 'Configured mail client successfully');
