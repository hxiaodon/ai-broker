/**
 * proto-router.js — 低保真原型页面跳转工具
 * 用途：统一管理原型内页面跳转，支持模拟状态切换
 */

(function () {
  // ─── 跳转函数 ──────────────────────────────────────────
  window.goto = function (path) {
    window.location.href = path;
  };

  // ─── 显示/隐藏元素（模拟状态切换）────────────────────
  window.showEl = function (id) {
    const el = document.getElementById(id);
    if (el) el.style.display = '';
  };
  window.hideEl = function (id) {
    const el = document.getElementById(id);
    if (el) el.style.display = 'none';
  };
  window.toggleEl = function (id) {
    const el = document.getElementById(id);
    if (el) el.style.display = el.style.display === 'none' ? '' : 'none';
  };

  // ─── 激活 Tab ──────────────────────────────────────────
  window.setTab = function (tabId) {
    document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.screen-panel').forEach(p => p.style.display = 'none');
    const tab = document.getElementById('tab-' + tabId);
    const panel = document.getElementById('panel-' + tabId);
    if (tab) tab.classList.add('active');
    if (panel) panel.style.display = '';
  };

  // ─── 激活分段控制器 ────────────────────────────────────
  window.setSegment = function (groupId, itemId) {
    const group = document.getElementById(groupId);
    if (!group) return;
    group.querySelectorAll('.seg-item').forEach(s => s.classList.remove('active'));
    const item = document.getElementById(itemId);
    if (item) item.classList.add('active');
  };

  // ─── 显示底部 Sheet ────────────────────────────────────
  window.showSheet = function (id) {
    const el = document.getElementById(id);
    if (el) { el.style.display = 'flex'; }
  };
  window.hideSheet = function (id) {
    const el = document.getElementById(id);
    if (el) { el.style.display = 'none'; }
  };

  // ─── 模拟 Toast 提示 ───────────────────────────────────
  window.showToast = function (msg, duration) {
    duration = duration || 2000;
    let toast = document.getElementById('_proto_toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = '_proto_toast';
      toast.className = 'toast';
      // 挂到 .phone 下（若存在），否则挂到 body
      const phone = document.querySelector('.phone');
      (phone || document.body).appendChild(toast);
    }
    toast.textContent = msg;
    toast.style.display = 'block';
    clearTimeout(toast._timer);
    toast._timer = setTimeout(function () { toast.style.display = 'none'; }, duration);
  };

  // ─── 步骤切换 ──────────────────────────────────────────
  window.setStep = function (containerId, activeStep) {
    const container = document.getElementById(containerId);
    if (!container) return;
    container.querySelectorAll('.step').forEach(function (s, i) {
      s.classList.remove('active', 'done');
      if (i + 1 < activeStep) s.classList.add('done');
      else if (i + 1 === activeStep) s.classList.add('active');
    });
  };

  // ─── 模拟加载状态 ──────────────────────────────────────
  window.simulateLoading = function (btnId, loadingText, successFn, delay) {
    delay = delay || 1200;
    const btn = document.getElementById(btnId);
    if (!btn) return;
    const original = btn.textContent;
    btn.textContent = loadingText || '加载中...';
    btn.disabled = true;
    btn.classList.add('btn-disabled');
    setTimeout(function () {
      btn.textContent = original;
      btn.disabled = false;
      btn.classList.remove('btn-disabled');
      if (typeof successFn === 'function') successFn();
    }, delay);
  };

  // ─── 页面初始化：自动隐藏所有非首屏 sheet ─────────────
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.sheet-overlay').forEach(function (el) {
      if (!el.dataset.visible) el.style.display = 'none';
    });
    document.querySelectorAll('.toast').forEach(function (el) {
      el.style.display = 'none';
    });
  });
})();
