// Type definitions for Scent 0.10.0
// Project: https://github.com/BlackDice/scent
// Definitions by: Marti Kaljuve <https://github.com/martikaljuve>

declare namespace Scent {
	interface INotifier<TContext> {
		notify(fn: (this: TContext, ...args) => void): void;
	}

	// Action

	interface ActionStatic {
		new <TData, TMeta>(name: any): ActionType<TData, TMeta>;
	}

	interface ActionType<TData = {}, TMeta = {}> {
		trigger(data: TData, meta?: TMeta): this;
		each(iterator: (action: ActionType<TData, TMeta>) => void, ctx: any);
		toString();

		time: number;
		data: TData;
		meta: TMeta;
	}

	export var Action: ActionStatic;

	// Engine

	type SystemFunction = (...args: any[]) => void;

	export class Engine {
		constructor(initializer?: (engine: Engine, provide: (name: string, injection: any) => void) => void);

		registerComponent(componentType: ComponentType, componentId?: any): void;
		accessComponent<T>(componentId: any): T & BaseComponent;
		createComponent<T>(componentId: any): ComponentType<T>;

		/**
		 * Adds existing entity to engine.
		 */
		addEntity(entity: Entity): Entity;

		/**
		 * Builds entity from array of components.
		 */
		buildEntity(components: (string | ComponentType | BaseComponent)[]): Entity;

		/**
		 * Number of entities in the engine.
		 */
		size: number;

		/**
		 * Adds a system to the engine.
		 */
		addSystem(system: SystemFunction);

		/**
		 * Adds multiple systems to the engine.
		 */
		addSystems(systems: (SystemFunction)[]);

		/**
		 * Starts the engine.
		 */
		start(done?: (err) => void): Engine;

		/**
		 * Updates the engine. Actions are processed, node types are updated
		 * and onUpdate callbacks are called.
		 */
		update(...args: any[]);

		/**
		 * Registers a callback that is called when update() method is invoked.
		 */
		onUpdate(callback: (...args: any[]) => void);

		getActionType<TData = any, TMeta = any>(actionName: any, noCreate?: boolean): ActionType<TData, TMeta>;

		triggerAction<TData = any, TMeta = any>(actionName: any, data?: TData, meta?: TMeta): Engine;

		onAction<TData = any, TMeta = any>(actionName: any, callback: (action: ActionType<TData, TMeta>) => void): Engine;

		getNodeType<T = { [key: string]: any }>(componentTypes: (string | ComponentType)[]): Node<T>;
	}

	// Entity

	export class Entity {
		/**
		 * Accepts optional array of component instances that are about to be
		 * added to entity right away.
		 */
		constructor(
			components?: (string | BaseComponent | ComponentType)[],
			componentProvider?: (componentName) => ComponentType
		);

		/**
		 * Adds component instance to entity. Only a single instance of one
		 * component type can be added. Trying to add component of same type
		 * preserves the previous one while issuing a log message to notify
		 * about a possible logic error.
		 */
		add(component: BaseComponent | ComponentType | string): Entity;

		/**
		 * Removes component type from the entity; removed component is marked
		 * for disposal.
		 */
		remove(component: ComponentType | string): Entity;

		/**
		 * Similar to add method, but disposes component of same type before
		 * adding new one.
		 */
		replace(component: BaseComponent | ComponentType | string): Entity;

		/**
		 * Returns whether the component type exists in entity. Passing true
		 * in second argument will consider currently disposed components.
		 */
		has(component: ComponentType | string, allowDisposed?: boolean): boolean;

		/**
		 * Retrieves component instance by specified type. Returns null if no
		 * component of such type is present. Passing true in the second
		 * argument will consider currently disposed elements.
		 */
		get<T>(component: ComponentType<T>, allowDisposed?: boolean): T & BaseComponent;

		/**
		 * Number of components in entity.
		 */
		size: number;

		/**
		 * Timestamp of the latest change in entity.
		 */
		changed: number;

		/**
		 * Retrieves list of components within entity. Optionally an array for
		 * storing results can be supplied.
		 * Expected to be called in context of entity instance.
		 */
		getAll(result?: any[]): ComponentType[];

		dispose(): void;

		/**
		 * Returns entity from pool of disposed ones or creates a new entity.
		 * Accepts array of components, same as Entity constructor.
		 */
		static pooled(components: ComponentType[]);

		static componentAdded: INotifier<Entity>;
		static componentRemoved: INotifier<Entity>;
	}

	// Component

	// e.g. var cBuilding = new Component('building', 'floors');
	interface Component {
		new <T = {}>(name: string, definition?: string): ComponentType<T>;
	}

	export var Component: Component;

	// e.g. var building = new cBuilding([3]);
	export interface ComponentType<T = {}> {
		new (data?: any[]): T & BaseComponent;

		typeName: string;
		typeFields: string[];
		typeIdentity: number;
		typeDefinition: string;

		pooled(): T & BaseComponent;
	}

	export interface BaseComponent {
		inspect(): Object;
		toString(): string;
	}

	export interface NodeItem {
		entityRef: Entity;
	}

	// Node
	export class Node<T> {
		constructor(componentTypes: (string | ComponentType)[], componentProvider?: (type: any) => ComponentType);

		head: T & NodeItem;
		tail: T & NodeItem;
		size: number;
		types: ComponentType[];

		/**
		 * Checks if entity fulfills component type constraints defined for
		 * node type.
		 */
		entityFits(entity: Entity): boolean;

		/**
		 * Adds a new entity to the list. It rejects entities that are already
		 * on the list or if required components are missing.
		 */
		addEntity(entity: Entity): Node<T>;

		/**
		 * Removes entity from the node type if it no longer fits in the node
		 * type constraints.
		 */
		removeEntity(entity: Entity): Node<T>;

		/**
		 * An entity that is not part of the node type will be checked against
		 * component type constraints and added if valid; Otherwise, entity is
		 * removed from node type forcefully.
		 */
		updateEntity(entity: Entity): Node<T>;

		/**
		 * Loops over node items.
		 */
		each(loopNodes: (node: T & NodeItem, ...args: any[]) => void, ...args: any[]): Node<T>;

		/**
		 * Finds the first node item matching a predicate.
		 */
		find(findPredicate: (node: T & NodeItem, ...args: any[]) => boolean): T & NodeItem;

		/**
		 * Registers a callback function that will be called whenever a new
		 * entity is added to the node type. Callbacks will be executed when
		 * finish() method is invoked.
		 */
		onAdded(callback: (node: T & NodeItem) => void): Node<T>;

		/**
		 * Similar to onAdded; invokes callbacks for each removed entity when
		 * finish() method is invoked.
		 */
		onRemoved(callback: (node: T & NodeItem) => void): Node<T>;

		/**
		 * Used to invoke registered onAdded and onRemoved callbacks.
		 */
		finish(): Node<T>;

		inspect(metaOnly?: boolean): Object;
	}
}

declare module 'scent' {
	export = Scent;
}

declare module 'scent/es6' {
	export = Scent;
}
