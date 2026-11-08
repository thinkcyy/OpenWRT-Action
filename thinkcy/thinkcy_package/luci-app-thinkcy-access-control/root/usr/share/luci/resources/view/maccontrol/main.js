'use strict';
'require view';
'require rpc';
'require uci';
'require ui';

var callGetKnownMacs = rpc.declare({
	object: 'maccontrol',
	method: 'get_known_macs',
	expect: { macs: [] }
});

var callListBlocked = rpc.declare({
	object: 'maccontrol',
	method: 'list_blocked',
	expect: { blocked: [] }
});

var callTempAllow = rpc.declare({
	object: 'maccontrol',
	method: 'temp_allow',
	params: [ 'mac', 'minutes' ]
});

var callRevokeTemp = rpc.declare({
	object: 'maccontrol',
	method: 'revoke_temp',
	params: [ 'mac' ]
});

var callRemoveBlock = rpc.declare({
	object: 'maccontrol',
	method: 'remove_block',
	params: [ 'mac' ]
});

var callAddSchedule = rpc.declare({
	object: 'maccontrol',
	method: 'add_schedule',
	params: [ 'mac', 'cron', 'minutes', 'remark' ]
});

var callDeleteSchedule = rpc.declare({
	object: 'maccontrol',
	method: 'delete_schedule',
	params: [ 'section' ]
});

var callToggleSchedule = rpc.declare({
	object: 'maccontrol',
	method: 'toggle_schedule',
	params: [ 'section', 'enabled' ]
});

return view.extend({
	load: function() {
		return Promise.all([
			callGetKnownMacs(),
			callListBlocked(),
			uci.load('maccontrol')
		]);
	},

	render: function(data) {
		var knownMacs = data[0] || [];
		var blockedList = data[1] || [];
		var self = this;

		var body = E('div', { 'class': 'cbi-map' }, [
			E('h2', {}, _('MAC 地址上网控制与定时计划')),
			E('div', { 'class': 'cbi-map-descr' }, _('支持基于系统的默认管控、基于 nftables timeout 的手动临时放行，以及多组基于 Crontab 的定时自动开放任务。'))
		]);

		var secControl = E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, _('手动临时放行')),
			E('div', { 'class': 'cbi-section-node' }, [
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('选择 MAC 地址')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('select', { 'id': 'select_mac', 'class': 'cbi-input-select' }, 
							knownMacs.map(function(item) {
								return E('option', { 'value': item.mac }, item.mac + ' - ' + item.info);
							})
						)
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('放行时长（分钟）')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('input', {
							'type': 'number',
							'id': 'input_minutes',
							'class': 'cbi-input-text',
							'min': '1',
							'value': '30'
						})
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }),
					E('div', { 'class': 'cbi-value-field' }, [
						E('button', {
							'class': 'btn cbi-button-action',
							'click': ui.createHandlerFn(this, 'handleTempAllow')
						}, _('确定放行'))
					])
				])
			])
		]);

		var secAddSchedule = E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, _('添加定时开放计划')),
			E('div', { 'class': 'cbi-section-node' }, [
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('目标 MAC 地址')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('select', { 'id': 'sched_mac', 'class': 'cbi-input-select' }, 
							knownMacs.map(function(item) {
								return E('option', { 'value': item.mac }, item.mac + ' - ' + item.info);
							})
						)
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('Crontab 表达式')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('input', {
							'type': 'text',
							'id': 'sched_cron',
							'class': 'cbi-input-text',
							'placeholder': '例如：0 20 * * * (每天 20:00 触发)'
						}),
						E('br'),
						E('small', { 'class': 'cbi-value-description' }, _('格式: 分 时 日 月 周 (例: "30 18 * * 1-5" 表示工作日 18:30)'))
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('定时放行时长（分钟）')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('input', {
							'type': 'number',
							'id': 'sched_minutes',
							'class': 'cbi-input-text',
							'min': '1',
							'value': '60'
						})
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }, _('计划备注')),
					E('div', { 'class': 'cbi-value-field' }, [
						E('input', {
							'type': 'text',
							'id': 'sched_remark',
							'class': 'cbi-input-text',
							'placeholder': '例如：晚间定时上网'
						})
					])
				]),
				E('div', { 'class': 'cbi-value' }, [
					E('label', { 'class': 'cbi-value-title' }),
					E('div', { 'class': 'cbi-value-field' }, [
						E('button', {
							'class': 'btn cbi-button-add',
							'click': ui.createHandlerFn(this, 'handleAddSchedule')
						}, _('保存定时计划'))
					])
				])
			])
		]);

		var sections = uci.sections('maccontrol', 'schedule');
		var schedRows = sections.map(function(s) {
			var isEnabled = (s.enabled === '1');
			return E('tr', { 'class': 'cbi-section-table-row' }, [
				E('td', { 'class': 'cbi-section-table-cell' }, s.remark || _('无备注')),
				E('td', { 'class': 'cbi-section-table-cell' }, s.mac),
				E('td', { 'class': 'cbi-section-table-cell' }, E('code', {}, s.cron)),
				E('td', { 'class': 'cbi-section-table-cell' }, s.minutes + _(' 分钟')),
				E('td', { 'class': 'cbi-section-table-cell' }, [
					E('span', { 'class': isEnabled ? 'label notice' : 'label warning' }, 
						isEnabled ? _('已启用') : _('已禁用')
					)
				]),
				E('td', { 'class': 'cbi-section-table-cell' }, [
					E('button', {
						'class': 'btn cbi-button-neutral',
						'style': 'margin-right: 5px;',
						'click': ui.createHandlerFn(self, 'handleToggleSchedule', s['.name'], isEnabled ? 0 : 1)
					}, isEnabled ? _('禁用') : _('启用')),
					E('button', {
						'class': 'btn cbi-button-remove',
						'click': ui.createHandlerFn(self, 'handleDeleteSchedule', s['.name'])
					}, _('删除'))
				])
			]);
		});

		var secSchedList = E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, _('当前已配置的定时计划列表')),
			E('table', { 'class': 'table cbi-section-table' }, [
				E('tr', { 'class': 'cbi-section-table-titles' }, [
					E('th', { 'class': 'cbi-section-table-cell' }, _('备注')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('目标 MAC')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('Cron 表达式')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('放行时长')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('状态')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('操作'))
				]),
				schedRows.length > 0 ? schedRows : E('tr', {}, [
					E('td', { 'colspan': 6, 'class': 'cbi-section-table-cell center' }, _('暂无定时开放计划'))
				])
			])
		]);

		var tableRows = blockedList.map(function(item) {
			var isTempAllow = (item.enabled === '0');
			var statusText = isTempAllow ? _('临时放行中') : _('默认封禁中');
			var statusClass = isTempAllow ? 'label notice' : 'label warning';
			
			var actions = [
				E('button', {
					'class': 'btn cbi-button-remove',
					'click': ui.createHandlerFn(self, 'handleRemoveBlock', item.mac)
				}, _('撤销默认管控'))
			];

			if (isTempAllow) {
				actions.unshift(E('button', {
					'class': 'btn cbi-button-neutral',
					'style': 'margin-right: 5px;',
					'click': ui.createHandlerFn(self, 'handleRevokeTemp', item.mac)
				}, _('提前恢复封禁')));
			}

			return E('tr', { 'class': 'cbi-section-table-row' }, [
				E('td', { 'class': 'cbi-section-table-cell' }, item.mac),
				E('td', { 'class': 'cbi-section-table-cell' }, [
					E('span', { 'class': statusClass }, statusText)
				]),
				E('td', { 'class': 'cbi-section-table-cell' }, 
					isTempAllow ? _('nftables 剩余倒计时: ') + item.expire : '-'
				),
				E('td', { 'class': 'cbi-section-table-cell' }, actions)
			]);
		});

		var secList = E('div', { 'class': 'cbi-section' }, [
			E('h3', {}, _('受默认管控的 MAC 清单及当前放行状态')),
			E('table', { 'class': 'table cbi-section-table' }, [
				E('tr', { 'class': 'cbi-section-table-titles' }, [
					E('th', { 'class': 'cbi-section-table-cell' }, _('MAC 地址')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('当前状态')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('动态超时状态')),
					E('th', { 'class': 'cbi-section-table-cell' }, _('操作'))
				]),
				tableRows.length > 0 ? tableRows : E('tr', {}, [
					E('td', { 'colspan': 4, 'class': 'cbi-section-table-cell center' }, _('暂无受管控的 MAC 地址'))
				])
			])
		]);

		body.appendChild(secControl);
		body.appendChild(secAddSchedule);
		body.appendChild(secSchedList);
		body.appendChild(secList);

		return body;
	},

	handleTempAllow: function(ev) {
		var mac = document.getElementById('select_mac').value;
		var minutes = parseInt(document.getElementById('input_minutes').value, 10);
		if (!mac || isNaN(minutes) || minutes <= 0) return;

		return callTempAllow(mac, minutes).then(function() {
			window.location.reload();
		});
	},

	handleAddSchedule: function(ev) {
		var mac = document.getElementById('sched_mac').value;
		var cron = document.getElementById('sched_cron').value.trim();
		var minutes = parseInt(document.getElementById('sched_minutes').value, 10);
		var remark = document.getElementById('sched_remark').value.trim();

		if (!mac || !cron || isNaN(minutes) || minutes <= 0) {
			ui.addNotification(null, E('p', {}, _('请填写完整有效的定时参数。')), 'error');
			return;
		}

		return callAddSchedule(mac, cron, minutes, remark).then(function() {
			window.location.reload();
		});
	},

	handleDeleteSchedule: function(sec, ev) {
		return callDeleteSchedule(sec).then(function() {
			window.location.reload();
		});
	},

	handleToggleSchedule: function(sec, enabled, ev) {
		return callToggleSchedule(sec, enabled).then(function() {
			window.location.reload();
		});
	},

	handleRevokeTemp: function(mac, ev) {
		return callRevokeTemp(mac).then(function() {
			window.location.reload();
		});
	},

	handleRemoveBlock: function(mac, ev) {
		return callRemoveBlock(mac).then(function() {
			window.location.reload();
		});
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
