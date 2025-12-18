-- 创建分公司表
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建收费站表
CREATE TABLE stations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    company_id INTEGER REFERENCES companies(id),
    address TEXT,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建班组表
CREATE TABLE groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    station_id INTEGER REFERENCES stations(id),
    leader_name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建收费员表
CREATE TABLE collectors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    employee_id VARCHAR(100) UNIQUE,
    company_id INTEGER REFERENCES companies(id),
    group_id INTEGER REFERENCES groups(id),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建监控员表
CREATE TABLE monitors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    employee_id VARCHAR(100) UNIQUE,
    company_id INTEGER REFERENCES companies(id),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建收费记录表
CREATE TABLE toll_records (
    id SERIAL PRIMARY KEY,
    plate_number VARCHAR(50),
    company_id INTEGER REFERENCES companies(id),
    station_id INTEGER REFERENCES stations(id),
    collector_id INTEGER REFERENCES collectors(id),
    monitor_id INTEGER REFERENCES monitors(id),
    amount DECIMAL(10,2),
    is_free BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建管理员用户表
CREATE TABLE admin_users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- super_admin, company_admin, station_admin
    company_id INTEGER REFERENCES companies(id),
    station_id INTEGER REFERENCES stations(id),
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_toll_records_company_id ON toll_records(company_id);
CREATE INDEX idx_toll_records_station_id ON toll_records(station_id);
CREATE INDEX idx_toll_records_created_at ON toll_records(created_at);
CREATE INDEX idx_toll_records_plate_number ON toll_records(plate_number);
CREATE INDEX idx_stations_company_id ON stations(company_id);
CREATE INDEX idx_collectors_company_id ON collectors(company_id);
CREATE INDEX idx_collectors_group_id ON collectors(group_id);
CREATE INDEX idx_groups_station_id ON groups(station_id);
CREATE INDEX idx_monitors_company_id ON monitors(company_id);
CREATE INDEX idx_admin_users_username ON admin_users(username);
CREATE INDEX idx_admin_users_company_id ON admin_users(company_id);
CREATE INDEX idx_admin_users_station_id ON admin_users(station_id);

-- 插入测试数据
INSERT INTO companies (name, address, phone) VALUES
('北京分公司', '北京市朝阳区', '010-12345678'),
('上海分公司', '上海市浦东新区', '021-87654321'),
('广州分公司', '广州市天河区', '020-11223344');

INSERT INTO stations (name, company_id, address, status) VALUES
('朝阳收费站', 1, '北京市朝阳区', 'active'),
('海淀收费站', 1, '北京市海淀区', 'active'),
('浦东收费站', 2, '上海市浦东新区', 'active'),
('天河收费站', 3, '广州市天河区', 'active');

INSERT INTO groups (name, station_id, leader_name, status) VALUES
('一班组', 1, '张三', 'active'),
('二班组', 1, '李四', 'active'),
('三班组', 2, '王五', 'active');

INSERT INTO collectors (name, employee_id, company_id, group_id, status) VALUES
('赵六', 'C001', 1, 1, 'active'),
('钱七', 'C002', 1, 1, 'active'),
('孙八', 'C003', 1, 2, 'active');

INSERT INTO monitors (name, employee_id, company_id, status) VALUES
('周九', 'M001', 1, 'active'),
('吴十', 'M002', 1, 'active');

INSERT INTO admin_users (username, password, role, company_id, station_id, status) VALUES
('admin', 'admin123', 'super_admin', NULL, NULL, 'active'),
('beijing_admin', 'beijing123', 'company_admin', 1, NULL, 'active'),
('shanghai_admin', 'shanghai123', 'company_admin', 2, NULL, 'active'),
('chaoyang_admin', 'chaoyang123', 'station_admin', 1, 1, 'active');

-- 插入测试收费记录
INSERT INTO toll_records (plate_number, company_id, station_id, collector_id, monitor_id, amount, is_free) VALUES
('京A12345', 1, 1, 1, 1, 50.00, FALSE),
('京B67890', 1, 1, 2, 1, 30.00, FALSE),
('京C11111', 1, 2, 3, 2, 0.00, TRUE),
('沪A22222', 2, 3, NULL, NULL, 45.00, FALSE),
('粤B33333', 3, 4, NULL, NULL, 25.00, FALSE);