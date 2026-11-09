'use strict';
'require view';
'require rpc';
'require ui';

var status = rpc.declare({ object: 'thinkcy_access', method: 'status', expect: {} });
var leases = rpc.declare({ object: 'thinkcy_access', method: 'leases', expect: {} });
var tasks = rpc.declare({ object: 'thinkcy_access', method: 'list_schedules', expect: {} });
var add = rpc.declare({ object: 'thinkcy_access', method: 'add_device', params: [ 'mac' ], expect: {} });
var remove = rpc.declare({ object: 'thinkcy_access', method: 'remove_device', params: [ 'mac' ], expect: {} });
var grant = rpc.declare({ object: 'thinkcy_access', method: 'grant', params: [ 'mac', 'minutes' ], expect: {} });
var save = rpc.declare({ object: 'thinkcy_access', method: 'save_schedule', params: [ 'id','name','mac','month','day','weekday','hour','minute','duration','enabled' ], expect: {} });
var del = rpc.declare({ object: 'thinkcy_access', method: 'delete_schedule', params: [ 'id' ], expect: {} });
var toggle = rpc.declare({ object: 'thinkcy_access', method: 'toggle_schedule', params: [ 'id','enabled' ], expect: {} });

function inp(v, ph) { return E('input', { type:'text', class:'cbi-input-text', value:v || '', placeholder:ph || '' }); }
function reload() { window.location.reload(); }
function editTask(t) {
	var name=inp(t ? t.name : '', 'Task name'), mac=inp(t ? t.mac : '', 'aa:bb:cc:dd:ee:ff');
	var month=inp(t ? t.month : '*','1-12 or *'), day=inp(t ? t.day : '*','1-31 or *');
	var weekday=inp(t ? t.weekday : '*','0-7 or *'), hour=inp(t ? t.hour : '8','0-23');
	var minute=inp(t ? t.minute : '0','0-59'), duration=inp(t ? t.duration : '30','minutes');
	var enabled=E('input',{type:'checkbox',checked:t ? !!t.enabled : true});
	ui.showModal(t ? _('Edit scheduled task') : _('Add scheduled task'), [
		E('div',{},[
			E('label',{},[_('Name'),name]), E('label',{},[_('Target MAC'),mac]),
			E('label',{},[_('Month'),month]), E('label',{},[_('Day'),day]),
			E('label',{},[_('Weekday'),weekday]), E('label',{},[_('Hour'),hour]),
			E('label',{},[_('Minute'),minute]), E('label',{},[_('Grant duration (minutes)'),duration]),
			E('label',{},[enabled,_('Enabled')])
		]),
		E('div',{class:'right'},[
			E('button',{class:'btn',click:ui.hideModal},[_('Cancel')]),' ',
			E('button',{class:'btn cbi-button-positive',click:function(){
				save(t ? t.id : '',name.value,mac.value,month.value,day.value,weekday.value,hour.value,minute.value,parseInt(duration.value,10),enabled.checked)
				.then(function(r){if(!r.ok) throw new Error(r.error || 'Save failed'); ui.hideModal(); reload();})
				.catch(function(e){ui.addNotification(null,E('p',{},[e.message]));});
			}},[_('Save')])
		])
	]);
}
return view.extend({
	load:function(){return Promise.all([status(),leases(),tasks()]);},
	render:function(d){
		var s=d[0], l=d[1].leases || [], ts=d[2].tasks || [], root=E('div',{class:'cbi-map'});
		root.appendChild(E('h2',{},[_('MAC Temporary WAN Access')]));
		root.appendChild(E('p',{},[_('Only registered MAC addresses are controlled. Router-local and internal-network traffic is not targeted.')]));
		var mac=inp(s.last_mac,'MAC address'), mins=inp(s.last_minutes || '30','minutes');
		var sel=E('select',{class:'cbi-input-select'}); sel.appendChild(E('option',{value:''},[_('Select DHCP client')]));
		l.forEach(function(x){sel.appendChild(E('option',{value:x.mac},[x.mac+' '+(x.ip||'')+' '+(x.hostname||'') ]));});
		sel.addEventListener('change',function(){mac.value=sel.value;});
		root.appendChild(E('h3',{},[_('Manual grant / managed MAC')]));
		root.appendChild(E('div',{},[sel,mac,mins,
			E('button',{class:'btn cbi-button-positive',click:function(){add(mac.value).then(reload);}},[_('Add managed MAC')]),' ',
			E('button',{class:'btn cbi-button-action',click:function(){grant(mac.value,parseInt(mins.value,10)).then(function(r){if(!r.ok) throw new Error(r.error); ui.addNotification(null,E('p',{},[_('Temporary grant submitted')]));}).catch(function(e){ui.addNotification(null,E('p',{},[e.message]));});}},[_('Grant temporary access')])
		]));
		var dt=E('table',{class:'table'}); dt.appendChild(E('tr',{},[E('th',{},[_('Managed MAC')]),E('th',{},[_('Action')])]));
		(s.devices||[]).forEach(function(m){dt.appendChild(E('tr',{},[E('td',{},[m]),E('td',{},[E('button',{class:'btn cbi-button-negative',click:function(){if(confirm(_('Remove management?'))) remove(m).then(reload);}},[_('Revoke default control')])])]));});
		root.appendChild(E('h3',{},[_('Managed devices')])); root.appendChild(dt);
		root.appendChild(E('h3',{},[_('Scheduled grants')]));
		root.appendChild(E('button',{class:'btn cbi-button-positive',click:function(){editTask(null);}},[_('Add scheduled task')]));
		var tt=E('table',{class:'table'}); tt.appendChild(E('tr',{},['Name','MAC','Minute Hour Day Month Weekday','Duration','Status','Actions'].map(function(x){return E('th',{},[_ (x)]);})));
		ts.forEach(function(t){tt.appendChild(E('tr',{},[
			E('td',{},[t.name]),E('td',{},[t.mac]),E('td',{},[t.minute+' '+t.hour+' '+t.day+' '+t.month+' '+t.weekday]),
			E('td',{},[t.duration+' min']),E('td',{},[t.enabled ? _('Enabled') : _('Disabled')]),
			E('td',{},[
				E('button',{class:'btn',click:function(){editTask(t);}},[_('Edit')]),' ',
				E('button',{class:'btn',click:function(){toggle(t.id,!t.enabled).then(reload);}},[t.enabled ? _('Disable') : _('Enable')]),' ',
				E('button',{class:'btn cbi-button-negative',click:function(){if(confirm(_('Delete task?'))) del(t.id).then(reload);}},[_('Delete')])
			])
		]));});
		root.appendChild(tt); return root;
	}
});
