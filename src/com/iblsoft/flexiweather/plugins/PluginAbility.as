package com.iblsoft.flexiweather.plugins
{
	import flash.utils.Dictionary;
	
	import mx.controls.Image;

	public class PluginAbility
	{
		public static const ACTION: String = "action";
		public static const DOCKLET: String = "docklet";
		public static const STORAGE: String = "storage";
		public static const CONSOLE: String = "console";
		public static const CHAT: String = "chat";
		public static const POPUP: String = "popup";
		public static const MULTI_VIEW: String = "multiView";
		public static const PERSISTENT_CONFIGURATION: String = "persistenConfiguration";
		public static const PANE_CLIENT: String = "paneClient";
		public static const INTERACTIVE_WIDGET_CLIENT: String = "interactiveWidgetClient";
		public static const LAYER_SELECTION_LISTENER: String = "layerSelectionListener";
		public static const LAYER_CHANGE_LISTENER: String = "layerChangeListener";
		public static const LAYER_OPTIONS_PROVIDER: String = "layerOptionsProvider";
		public static const LAYER_BEHAVIOUR: String = "layerBehaviour";
		public static const MENU_ITEM: String = "menuItem";
		public static const MENU_ITEM_CLICK_LISTENER: String = "menuItemClickListener";
		public static const SUBMENU_ITEM: String = "submenuItem";
		public static const LOCAL_COMMUNICATION: String = "localCommunication";
		
		private var ms_abilityType: String;
		private var m_classOrInstance: Object;
		private var ms_id: String;
		private var ms_plugin_id: String;
		private var m_metadata: Object = new Object;

		function PluginAbility(s_abilityType: String, s_id: String, s_plugin_id: String, classOrInstance: Object)
		{
			ms_abilityType = s_abilityType;
			ms_id = s_id;
			ms_plugin_id = s_plugin_id;
			m_classOrInstance = classOrInstance;
		}

		public static function action(classOrInstance: Object,
				s_id: String, s_plugin_id: String, s_name: String, s_buttonType: String, icon: Class): PluginAbility
		{
			return new PluginAbility(PluginAbility.ACTION, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name)
					.withMetadata("buttonType", s_buttonType)
					.withMetadata("icon", icon);
		}

		public static function docklet(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.DOCKLET, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name);
		}

		public static function popup(classOrInstance: Object,
				s_id: String, s_name: String, b_isModal: Boolean, s_plugin_id: String = null): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.POPUP, s_id, s_plugin_id, classOrInstance);
			ability.withMetadata("name", s_name);
			ability.withMetadata("isModal", b_isModal);
			return ability;
		}

		public static function chat(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.CHAT, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name);
		}

		public static function multiView(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.MULTI_VIEW, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name);
		}

		public static function persistentConfiguration(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.PERSISTENT_CONFIGURATION, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name);
		}

		public static function paneClient(classOrInstance: Object,
				s_id: String = null, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.PANE_CLIENT, s_id, s_plugin_id, classOrInstance);
		}

		public static function interactiveWidgetClient(classOrInstance: Object,
				s_id: String = null, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.INTERACTIVE_WIDGET_CLIENT, s_id, s_plugin_id, classOrInstance);
		}

		public static function layerOptionsProvider(classOrInstance: Object,
				s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.LAYER_OPTIONS_PROVIDER, s_id, s_plugin_id, classOrInstance);
		}

		public static function layerBehaviour(classOrInstance: Object,
				s_id: String, s_name: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.LAYER_BEHAVIOUR, s_id, s_plugin_id, classOrInstance)
					.withMetadata("name", s_name);
		}

		/**
		 * Plugin ability, which adds main menu item to main BrowsingWeather menu
		 *  
		 * @param classOrInstance
		 * @param s_menu_id
		 * @param s_name
		 * @param i_priority
		 * @param s_plugin_id
		 * @return 
		 * 
		 */		
		public static function menuItem(classOrInstance: Object, s_plugin_id: String,
				s_menu_id: String, s_name: String, i_priority: int): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.MENU_ITEM, s_menu_id, s_plugin_id, classOrInstance)
			ability.withMetadata("name", s_name);
			ability.withMetadata("priority", i_priority);
			return ability;
		}

		/**
		 * Plugin ability, which adds listener to any main BrowsingWeather menu item click
		 *   
		 * @param classOrInstance
		 * @param s_mainMenu_id
		 * @param s_menu_id
		 * @param s_name
		 * @param i_priority
		 * @param s_type
		 * @param f_callback
		 * @param s_plugin_id
		 * @param s_menuString
		 * @return 
		 * 
		 */		
		public static function menuClickListener(classOrInstance: Object, s_plugin_id: String,
				s_mainMenu_id: String,  s_itemIDSubstring: String, f_callback: Function): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.MENU_ITEM_CLICK_LISTENER, s_mainMenu_id, s_plugin_id, classOrInstance)
			ability.withMetadata("itemIDSubstring", s_itemIDSubstring);
			ability.withMetadata("callback", f_callback);
			return ability;
		}
		
		/**
		 * Plugin ability, which adds submenu item to main BrowsingWeather menu
		 *  
		 * @param classOrInstance
		 * @param s_mainMenu_id
		 * @param s_menu_id
		 * @param s_name
		 * @param i_priority
		 * @param s_type
		 * @param f_callback
		 * @param s_plugin_id
		 * @param s_menuString
		 * @return 
		 * 
		 */		
		public static function submenuItem(classOrInstance: Object, s_plugin_id: String,
				s_mainMenu_id: String, s_menu_id: String, s_name: String, i_priority: int, s_type: String = '', f_callback: Function = null, s_menuString: String = ''): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.SUBMENU_ITEM, s_menu_id, s_plugin_id, classOrInstance)
			ability.withMetadata("name", s_name);
			ability.withMetadata("mainMenuID", s_mainMenu_id);
			ability.withMetadata("priority", i_priority);
			ability.withMetadata("callback", f_callback);
			ability.withMetadata("type", s_type);
			ability.withMetadata("menuString", s_menuString);
			return ability;
		}

		public static function localCommunication(classOrInstance: Object,
				s_id: String, s_plugin_id: String = null): PluginAbility
		{
			var ability: PluginAbility = new PluginAbility(PluginAbility.LOCAL_COMMUNICATION, s_id, s_plugin_id, classOrInstance)
			return ability;
			
		}
		
		public static function storage(classOrInstance: Object,
				s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.STORAGE, s_id, s_plugin_id, classOrInstance);
//			.withMetadata("name", s_name);
		}

		public static function console(classOrInstance: Object,
				s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(PluginAbility.CONSOLE, s_id, s_plugin_id, classOrInstance);
//			.withMetadata("name", s_name);
		}

		public static function custom(s_abilityType: String, classOrInstance: Object, s_id: String, s_plugin_id: String = null): PluginAbility
		{
			return new PluginAbility(s_abilityType, s_id, s_plugin_id, classOrInstance);
		}

		public function withMetadata(s_key: String, value: Object): PluginAbility
		{
			m_metadata[s_key] = value;
			return this;
		}

		public function getImplementationInstance(plugin: IPlugin): IAbility
		{
			if (m_classOrInstance is Class)
			{
				var instance: IAbility = IAbility(new m_classOrInstance());
				instance.bindToPlugin(plugin);
				return instance;
			}
			else
				return IAbility(m_classOrInstance);
		}

		public function removeMetadata(s_key: String): void
		{
			if (s_key in m_metadata)
				delete m_metadata[s_key];
		}

		public function updateMetadata(s_key: String, newValue: Object): void
		{
			if (s_key in m_metadata)
				m_metadata[s_key] = newValue;
		}

		public function getMetadata(s_key: String, defaultValue: Object = null): Object
		{
			if (s_key in m_metadata)
				return m_metadata[s_key];
			else
				return defaultValue;
		}

		// getters and setters
		public function get id(): String
		{
			return ms_id;
		}

		public function get pluginId(): String
		{
			return ms_plugin_id;
		}

		public function get abilityType(): String
		{
			return ms_abilityType;
		}

		public function get metadata(): Object
		{
			return m_metadata;
		}
	}
}
