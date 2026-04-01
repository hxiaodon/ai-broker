/*
 * proto-router.js — 高保真原型导航工具
 * 提供页面跳转、状态切换、Toast 提示等辅助函数
 */

/**
 * 页面导航
 * @param {string} url - 目标页面 URL（相对或绝对）
 */
function goto(url) {
  window.location.href = url;
}

/**
 * 显示 Toast 提示
 * @param {string} message - 提示文本
 * @param {number} duration - 显示时长（毫秒，默认2000）
 */
function showToast(message, duration = 2000) {
  const toast = document.createElement('div');
  toast.className = 'toast';
  toast.textContent = message;

  // 避免重复创建
  const existing = document.querySelector('.toast');
  if (existing) existing.remove();

  document.body.appendChild(toast);

  // 自动移除
  setTimeout(() => {
    toast.style.animation = 'slideOutRight var(--transition-base)';
    setTimeout(() => toast.remove(), 150);
  }, duration);
}

/**
 * 切换 Modal/Sheet 显示
 * @param {string} id - 元素 ID
 * @param {boolean} show - 显示或隐藏
 */
function toggleOverlay(id, show) {
  const overlay = document.getElementById(id);
  if (!overlay) return;

  if (show === undefined) {
    // 切换模式
    overlay.style.display = overlay.style.display === 'flex' ? 'none' : 'flex';
  } else {
    // 明确设置
    overlay.style.display = show ? 'flex' : 'none';
  }
}

function showSheet(id) {
  toggleOverlay(id, true);
}

function hideSheet(id) {
  toggleOverlay(id, false);
}

function showPanel(id) {
  const panel = document.getElementById(id);
  if (panel) panel.style.display = 'block';
}

function hidePanel(id) {
  const panel = document.getElementById(id);
  if (panel) panel.style.display = 'none';
}

/**
 * 设置 Tab/Segmented 激活状态
 * @param {string} containerSelector - 容器选择器（.tab-bar, .segmented 等）
 * @param {string} activeSelector - 激活项选择器
 */
function setActiveTab(containerSelector, activeSelector) {
  const container = document.querySelector(containerSelector);
  if (!container) return;

  // 移除所有 active
  container.querySelectorAll('[class*="active"]').forEach(el => {
    el.classList.remove('active');
  });

  // 添加 active 到目标元素
  const activeElement = container.querySelector(activeSelector);
  if (activeElement) {
    activeElement.classList.add('active');
  }
}

/**
 * 状态切换（用于 Dev 工具栏演示不同状态）
 * @param {string} stateName - 状态名（'loading', 'empty', 'error', 'success'）
 */
function setState(stateName) {
  // 隐藏所有状态容器
  document.querySelectorAll('[data-state]').forEach(el => {
    el.style.display = 'none';
  });

  // 显示目标状态
  const stateElement = document.querySelector(`[data-state="${stateName}"]`);
  if (stateElement) {
    stateElement.style.display = 'block';
  }

  // 更新按钮状态
  document.querySelectorAll('.dev-state-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.state === stateName);
  });
}

/**
 * 获取 URL 查询参数
 * @param {string} key - 参数名
 * @returns {string|null} 参数值或 null
 */
function getQueryParam(key) {
  const params = new URLSearchParams(window.location.search);
  return params.get(key);
}

/**
 * 格式化数字为货币字符串
 * @param {number} value - 数值
 * @param {string} currency - 货币符号（默认 $）
 * @returns {string} 格式化后的字符串
 */
function formatCurrency(value, currency = '$') {
  return currency + value.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/**
 * 格式化百分比
 * @param {number} value - 百分比值（0-100）
 * @param {number} decimals - 小数位数
 * @returns {string} 格式化后的字符串（如 "+2.14%"）
 */
function formatPercent(value, decimals = 2) {
  const sign = value >= 0 ? '+' : '';
  return sign + value.toFixed(decimals) + '%';
}

/**
 * 处理表单提交
 * @param {Event} e - 提交事件
 * @param {Function} callback - 提交后的回调函数
 */
function handleFormSubmit(e, callback) {
  e.preventDefault();

  // 这里在实际应用中会向后端发送数据
  // 演示原型中直接调用回调函数
  if (callback) {
    callback();
  }
}

/**
 * 深度复制对象（用于状态管理）
 * @param {object} obj - 要复制的对象
 * @returns {object} 深度复制后的对象
 */
function deepCopy(obj) {
  return JSON.parse(JSON.stringify(obj));
}

/**
 * 防抖函数（用于输入框、搜索等）
 * @param {Function} func - 要执行的函数
 * @param {number} wait - 延迟时间（毫秒）
 * @returns {Function} 防抖后的函数
 */
function debounce(func, wait = 300) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * 节流函数（用于滚动、resize 等高频事件）
 * @param {Function} func - 要执行的函数
 * @param {number} limit - 限制时间（毫秒）
 * @returns {Function} 节流后的函数
 */
function throttle(func, limit = 300) {
  let inThrottle;
  return function executedFunction(...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

/**
 * 初始化页面（在 onload 或 DOMContentLoaded 时调用）
 * 自动处理导航、焦点管理等
 */
function initProto() {
  // 禁用手机端默认长按菜单
  document.addEventListener('contextmenu', (e) => {
    if (window.innerWidth < 500) {
      e.preventDefault();
    }
  });

  // 为所有外部链接添加 target="_blank"
  document.querySelectorAll('a[href^="http"]').forEach((link) => {
    link.target = '_blank';
    link.rel = 'noopener noreferrer';
  });

  // 初始化状态切换器（如果存在）
  const devBtns = document.querySelectorAll('.dev-state-btn');
  if (devBtns.length > 0) {
    devBtns.forEach((btn) => {
      btn.addEventListener('click', () => {
        setState(btn.dataset.state);
      });
    });

    // 默认显示第一个状态
    if (devBtns[0]?.dataset.state) {
      setState(devBtns[0].dataset.state);
    }
  }

  console.log('%c[ProtoRouter] Initialized', 'color: #1A73E8; font-weight: bold;');
}

// 页面加载时自动初始化
document.addEventListener('DOMContentLoaded', initProto);
