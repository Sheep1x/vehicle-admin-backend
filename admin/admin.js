// Supabase 配置
const SUPABASE_URL = 'https://codvnervcuxohwtxotpn.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZHZuZXJ2Y3V4b2h3dHhvdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MTg0MjQsImV4cCI6MjA4MTA5NDQyNH0.FrxgBbqYWmlhrSKZPLtZzn1DMcVEwyGTHs4mKYUuUTQ'

// 初始化 Supabase 客户端
if (typeof window !== 'undefined' && window.supabase && !window.supabase._initialized) {
  window.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  window.supabase._initialized = true;
}

// 全局变量
let currentTab = 'records'
let allRecords = []
let filteredRecords = []
let allCompanies = []
let allStations = []
let allGroups = []
let allCollectors = []
let allMonitors = []
let allShifts = []
let allUsers = []
let startDate = ''
let endDate = ''
let selectedStationId = ''
let currentUser = null

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', async () => {
  const savedUser = localStorage.getItem('admin_user')
  if (savedUser) {
    currentUser = JSON.parse(savedUser)
    showMainApp()
  } else {
    await loadUsers()
  }
})

// 登录处理
async function handleLogin(event) {
  event.preventDefault()
  
  const username = document.getElementById('login-username').value.trim()
  const password = document.getElementById('login-password').value.trim()
  const errorElement = document.getElementById('login-error')
  
  errorElement.textContent = ''
  errorElement.style.display = 'none'
  
  try {
    const { data: user, error } = await window.supabase
      .from('admin_users')
      .select('*')
      .eq('username', username)
      .single()
    
    if (error) {
      if (error.code === 'PGRST116') {
        errorElement.textContent = '用户名或密码错误'
        errorElement.style.display = 'block'
      } else {
        throw error
      }
      return
    }
    
    if (user && user.password === password) {
      currentUser = user
      localStorage.setItem('admin_user', JSON.stringify(currentUser))
      showMainApp()
    } else {
      errorElement.textContent = '用户名或密码错误'
      errorElement.style.display = 'block'
    }
  } catch (error) {
    errorElement.textContent = `登录失败: ${error.message || '未知错误'}`
    errorElement.style.display = 'block'
  }
}

// 显示主应用
async function showMainApp() {
  document.getElementById('current-username').textContent = currentUser.username
  document.getElementById('current-role').textContent = getRoleName(currentUser.role)
  
  document.querySelector('.login-container').style.display = 'none'
  document.querySelector('.container').classList.add('active')
  
  setUserPermissions()
  await loadAllData()
  await initFilters()
  renderCurrentTab()
}

// 获取角色名称
function getRoleName(role) {
  const roleMap = {
    'super_admin': '超级管理员',
    'company_admin': '分公司管理员',
    'station_admin': '收费站管理员'
  }
  return roleMap[role] || role
}

// 设置用户权限
function setUserPermissions() {
  const menuItems = document.querySelectorAll('.menu-item')
  
  if (currentUser && currentUser.role === 'station_admin') {
    menuItems.forEach(item => {
      const text = item.querySelector('.menu-text').textContent
      if (text === '分公司管理' || text === '收费站管理') {
        item.style.display = 'none'
      }
    })
  }
}

// 退出登录
function handleLogout() {
  localStorage.removeItem('admin_user')
  currentUser = null
  
  document.querySelector('.container').classList.remove('active')
  document.querySelector('.login-container').style.display = 'flex'
  
  document.getElementById('login-username').value = ''
  document.getElementById('login-password').value = ''
  document.getElementById('login-error').style.display = 'none'
}

// 初始化筛选器
async function initFilters() {
  // 填充分公司筛选下拉框
  const filters = ['group-company-filter', 'collector-company-filter', 'monitor-company-filter', 
                  'record-company-filter', 'station-company-filter']
  
  filters.forEach(filterId => {
    const filter = document.getElementById(filterId)
    if (filter && allCompanies.length > 0) {
      filter.innerHTML = '<option value="">所有分公司</option>'
      allCompanies.forEach(company => {
        const option = document.createElement('option')
        option.value = company.id
        option.textContent = company.name
        filter.appendChild(option)
      })
    }
  })
}

// 加载所有数据
async function loadAllData() {
  try {
    await Promise.all([
      loadRecords(),
      loadCompanies(),
      loadStations(),
      loadGroups(),
      loadCollectors(),
      loadMonitors(),
      loadUsers()
    ])
  } catch (error) {
    console.error('加载数据失败:', error)
    showNotification('加载数据失败，请稍后重试', 'error')
  }
}

// 加载登记记录
async function loadRecords() {
  try {
    let query = window.supabase.from('toll_records').select('*')
    
    // 根据用户角色限制数据访问
    if (currentUser.role === 'company_admin') {
      query = query.eq('company_id', currentUser.company_id)
    } else if (currentUser.role === 'station_admin') {
      query = query.eq('station_id', currentUser.station_id)
    }
    
    const { data, error } = await query.order('created_at', { ascending: false })
    
    if (error) throw error
    allRecords = data || []
    filteredRecords = [...allRecords]
  } catch (error) {
    console.error('加载登记记录失败:', error)
    allRecords = []
    filteredRecords = []
  }
}

// 加载分公司
async function loadCompanies() {
  try {
    const { data, error } = await window.supabase.from('companies').select('*').order('name')
    if (error) throw error
    allCompanies = data || []
  } catch (error) {
    console.error('加载分公司失败:', error)
    allCompanies = []
  }
}

// 加载收费站
async function loadStations() {
  try {
    let query = window.supabase.from('stations').select('*').order('name')
    
    // 根据用户角色限制数据访问
    if (currentUser.role === 'company_admin') {
      query = query.eq('company_id', currentUser.company_id)
    } else if (currentUser.role === 'station_admin') {
      query = query.eq('id', currentUser.station_id)
    }
    
    const { data, error } = await query
    if (error) throw error
    allStations = data || []
  } catch (error) {
    console.error('加载收费站失败:', error)
    allStations = []
  }
}

// 渲染当前标签页
function renderCurrentTab() {
  switch (currentTab) {
    case 'records':
      renderRecords()
      break
    case 'companies':
      renderCompanies()
      break
    case 'stations':
      renderStations()
      break
    case 'groups':
      renderGroups()
      break
    case 'collectors':
      renderCollectors()
      break
    case 'monitors':
      renderMonitors()
      break
    case 'users':
      renderUsers()
      break
  }
}

// 渲染登记记录
function renderRecords() {
  const tbody = document.querySelector('#records-table tbody')
  const template = document.getElementById('record-row-template')
  
  tbody.innerHTML = ''
  
  filteredRecords.forEach(record => {
    const row = template.content.cloneNode(true)
    
    row.querySelector('.record-date').textContent = formatDate(record.created_at)
    row.querySelector('.record-plate').textContent = record.plate_number || '-'
    row.querySelector('.record-company').textContent = getCompanyName(record.company_id)
    row.querySelector('.record-station').textContent = getStationName(record.station_id)
    row.querySelector('.record-amount').textContent = record.amount ? `¥${record.amount}` : '-'
    row.querySelector('.record-status').textContent = record.is_free ? '免费' : '收费'
    
    tbody.appendChild(row)
  })
  
  updateRecordCount()
}

// 格式化日期
function formatDate(dateString) {
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}

// 获取分公司名称
function getCompanyName(companyId) {
  const company = allCompanies.find(c => c.id === companyId)
  return company ? company.name : '-'
}

// 获取收费站名称
function getStationName(stationId) {
  const station = allStations.find(s => s.id === stationId)
  return station ? station.name : '-'
}

// 更新记录计数
function updateRecordCount() {
  const countElement = document.querySelector('.record-count')
  if (countElement) {
    countElement.textContent = `共 ${filteredRecords.length} 条记录`
  }
}

// 显示通知
function showNotification(message, type = 'info') {
  const notification = document.createElement('div')
  notification.className = `notification notification-${type}`
  notification.textContent = message
  
  document.body.appendChild(notification)
  
  setTimeout(() => {
    notification.classList.add('show')
  }, 100)
  
  setTimeout(() => {
    notification.classList.remove('show')
    setTimeout(() => {
      document.body.removeChild(notification)
    }, 300)
  }, 3000)
}

// 导出功能
function exportToExcel() {
  try {
    const data = filteredRecords.map(record => ({
      '日期': formatDate(record.created_at),
      '车牌号': record.plate_number || '-',
      '分公司': getCompanyName(record.company_id),
      '收费站': getStationName(record.station_id),
      '金额': record.amount || 0,
      '状态': record.is_free ? '免费' : '收费'
    }))
    
    const ws = XLSX.utils.json_to_sheet(data)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, '登记记录')
    
    const fileName = `车辆登记记录_${new Date().toISOString().split('T')[0]}.xlsx`
    XLSX.writeFile(wb, fileName)
    
    showNotification('导出成功！', 'success')
  } catch (error) {
    console.error('导出失败:', error)
    showNotification('导出失败，请稍后重试', 'error')
  }
}

// 筛选功能
function filterRecords() {
  const startDate = document.getElementById('start-date').value
  const endDate = document.getElementById('end-date').value
  const companyId = document.getElementById('record-company-filter').value
  const stationId = document.getElementById('record-station-filter').value
  
  filteredRecords = allRecords.filter(record => {
    let match = true
    
    // 日期筛选
    if (startDate) {
      match = match && new Date(record.created_at) >= new Date(startDate)
    }
    if (endDate) {
      match = match && new Date(record.created_at) <= new Date(endDate + 'T23:59:59')
    }
    
    // 分公司筛选
    if (companyId) {
      match = match && record.company_id == companyId
    }
    
    // 收费站筛选
    if (stationId) {
      match = match && record.station_id == stationId
    }
    
    return match
  })
  
  renderRecords()
}

// 重置筛选
function resetFilters() {
  document.getElementById('start-date').value = ''
  document.getElementById('end-date').value = ''
  document.getElementById('record-company-filter').value = ''
  document.getElementById('record-station-filter').value = ''
  
  filteredRecords = [...allRecords]
  renderRecords()
}

// 切换标签页
function switchTab(tabName) {
  currentTab = tabName
  
  // 更新菜单激活状态
  document.querySelectorAll('.menu-item').forEach(item => {
    item.classList.remove('active')
  })
  document.querySelector(`[onclick="switchTab('${tabName}')"]`).parentElement.classList.add('active')
  
  // 显示对应内容
  document.querySelectorAll('.content-section').forEach(section => {
    section.style.display = 'none'
  })
  document.getElementById(`${tabName}-section`).style.display = 'block'
  
  // 渲染内容
  renderCurrentTab()
}

// 其他管理功能的简化实现
async function loadUsers() {
  try {
    let query = window.supabase.from('admin_users').select('*')
    
    // 根据用户角色限制数据访问
    if (currentUser && currentUser.role === 'company_admin') {
      query = query.eq('company_id', currentUser.company_id)
    } else if (currentUser && currentUser.role === 'station_admin') {
      query = query.eq('station_id', currentUser.station_id)
    }
    
    const { data, error } = await query.order('username')
    if (error) throw error
    allUsers = data || []
  } catch (error) {
    console.error('加载用户失败:', error)
    allUsers = []
  }
}

function renderCompanies() {
  // 分公司管理界面渲染
  console.log('渲染分公司管理界面')
}

function renderStations() {
  // 收费站管理界面渲染
  console.log('渲染收费站管理界面')
}

function renderGroups() {
  // 班组管理界面渲染
  console.log('渲染班组管理界面')
}

function renderCollectors() {
  // 收费员管理界面渲染
  console.log('渲染收费员管理界面')
}

function renderMonitors() {
  // 监控员管理界面渲染
  console.log('渲染监控员管理界面')
}

function renderUsers() {
  // 用户管理界面渲染
  console.log('渲染用户管理界面')
}