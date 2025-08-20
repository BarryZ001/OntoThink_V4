import React, { useState, useCallback } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import ReactFlow, {
  Background,
  Controls,
  Node,
  Edge,
  addEdge,
  Connection,
  useNodesState,
  useEdgesState,
  MarkerType,
} from 'reactflow';
import 'reactflow/dist/style.css';
import { 
  PlusIcon, 
  TrashIcon, 
  ArrowsPointingOutIcon, 
  DocumentDuplicateIcon,
  LinkIcon,
  LightBulbIcon,
  QuestionMarkCircleIcon,
  ExclamationCircleIcon,
  InformationCircleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';

// Custom node types
import CustomNode from '../components/nodes/CustomNode';

// Node types
const nodeTypes = {
  custom: CustomNode,
};

const initialNodes: Node[] = [
  {
    id: '1',
    type: 'custom',
    data: { 
      label: '中心主题',
      type: 'main',
      content: '点击编辑主题',
    },
    position: { x: 250, y: 5 },
  },
  {
    id: '2',
    type: 'custom',
    data: { 
      label: '子主题 1',
      type: 'child',
      content: '点击编辑内容',
    },
    position: { x: 100, y: 100 },
  },
  {
    id: '3',
    type: 'custom',
    data: { 
      label: '子主题 2',
      type: 'child',
      content: '点击编辑内容',
    },
    position: { x: 400, y: 100 },
  },
];

const initialEdges: Edge[] = [
  { 
    id: 'e1-2', 
    source: '1', 
    target: '2',
    type: 'smoothstep',
    markerEnd: {
      type: MarkerType.ArrowClosed,
    },
  },
  { 
    id: 'e1-3', 
    source: '1', 
    target: '3',
    type: 'smoothstep',
    markerEnd: {
      type: MarkerType.ArrowClosed,
    },
  },
];

const GraphEditorPage: React.FC = () => {
  const { graphId } = useParams<{ graphId: string }>();
  const navigate = useNavigate();
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);

  const onConnect = useCallback(
    (params: Connection) => {
      setEdges((eds) =>
        addEdge(
          {
            ...params,
            type: 'smoothstep',
            markerEnd: {
              type: MarkerType.ArrowClosed,
            },
          },
          eds
        )
      );
    },
    [setEdges]
  );

  const onNodeClick = useCallback((event: React.MouseEvent, node: Node) => {
    setSelectedNode(node);
  }, []);

  const onPaneClick = useCallback(() => {
    setSelectedNode(null);
  }, []);

  const addNewNode = useCallback(() => {
    const newNodeId = (nodes.length + 1).toString();
    const newNode: Node = {
      id: newNodeId,
      type: 'custom',
      data: { 
        label: `节点 ${newNodeId}`, 
        type: 'child',
        content: '点击编辑内容',
      },
      position: { x: 300, y: 200 },
    };
    
    setNodes((nds) => [...nds, newNode]);
    
    if (selectedNode) {
      const newEdge: Edge = {
        id: `e${selectedNode.id}-${newNodeId}`,
        source: selectedNode.id,
        target: newNodeId,
        type: 'smoothstep',
        markerEnd: {
          type: MarkerType.ArrowClosed,
        },
      };
      setEdges((eds) => [...eds, newEdge]);
    }
  }, [nodes.length, selectedNode, setEdges, setNodes]);

  const deleteSelectedNode = useCallback(() => {
    if (selectedNode) {
      setNodes((nds) => nds.filter((node) => node.id !== selectedNode.id));
      setEdges((eds) => 
        eds.filter(
          (edge) =>
            edge.source !== selectedNode.id && edge.target !== selectedNode.id
        )
      );
      setSelectedNode(null);
    }
  }, [selectedNode, setEdges, setNodes]);

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch((err) => {
        console.error(`Error attempting to enable fullscreen: ${err.message}`);
      });
      setIsFullscreen(true);
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen();
        setIsFullscreen(false);
      }
    }
  };

  const duplicateNode = useCallback(() => {
    if (selectedNode) {
      const newNodeId = (nodes.length + 1).toString();
      const newNode: Node = {
        ...selectedNode,
        id: newNodeId,
        position: {
          x: selectedNode.position.x + 50,
          y: selectedNode.position.y + 50,
        },
      };
      setNodes((nds) => [...nds, newNode]);
    }
  }, [selectedNode, nodes.length, setNodes]);

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="bg-white border-b border-gray-200 px-4 py-2 flex items-center justify-between">
        <div className="flex items-center space-x-2">
          <button
            onClick={() => navigate('/')}
            className="p-2 text-gray-500 hover:text-gray-700 focus:outline-none"
            title="返回"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z"
                clipRule="evenodd"
              />
            </svg>
          </button>
          <h1 className="text-lg font-medium text-gray-900">
            思维图谱 {graphId}
          </h1>
        </div>

        <div className="flex items-center space-x-2">
          <button
            onClick={addNewNode}
            className="p-2 text-gray-500 hover:text-primary-600 focus:outline-none"
            title="添加节点"
          >
            <PlusIcon className="h-5 w-5" />
          </button>
          
          {selectedNode && (
            <>
              <button
                onClick={duplicateNode}
                className="p-2 text-gray-500 hover:text-primary-600 focus:outline-none"
                title="复制节点"
              >
                <DocumentDuplicateIcon className="h-5 w-5" />
              </button>
              <button
                onClick={deleteSelectedNode}
                className="p-2 text-gray-500 hover:text-red-600 focus:outline-none"
                title="删除节点"
              >
                <TrashIcon className="h-5 w-5" />
              </button>
            </>
          )}
          
          <div className="h-6 w-px bg-gray-300 mx-1"></div>
          
          <button
            onClick={toggleFullscreen}
            className="p-2 text-gray-500 hover:text-primary-600 focus:outline-none"
            title={isFullscreen ? '退出全屏' : '全屏'}
          >
            <ArrowsPointingOutIcon className="h-5 w-5" />
          </button>
          
          <button className="p-2 text-gray-500 hover:text-primary-600 focus:outline-none" title="保存">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fillRule="evenodd"
                d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                clipRule="evenodd"
              />
            </svg>
          </button>
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Side panel */}
        <div className="w-64 bg-white border-r border-gray-200 p-4 overflow-y-auto">
          <h2 className="text-lg font-medium text-gray-900 mb-4">节点属性</h2>
          
          {selectedNode ? (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  节点类型
                </label>
                <select
                  className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
                  value={selectedNode.data.type}
                  onChange={(e) => {
                    setNodes((nds) =>
                      nds.map((node) =>
                        node.id === selectedNode.id
                          ? {
                              ...node,
                              data: {
                                ...node.data,
                                type: e.target.value,
                              },
                            }
                          : node
                      )
                    );
                  }}
                >
                  <option value="main">主要</option>
                  <option value="child">子节点</option>
                  <option value="question">问题</option>
                  <option value="idea">想法</option>
                  <option value="note">笔记</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  标题
                </label>
                <input
                  type="text"
                  className="shadow-sm focus:ring-primary-500 focus:border-primary-500 block w-full sm:text-sm border-gray-300 rounded-md"
                  value={selectedNode.data.label}
                  onChange={(e) => {
                    setNodes((nds) =>
                      nds.map((node) =>
                        node.id === selectedNode.id
                          ? {
                              ...node,
                              data: {
                                ...node.data,
                                label: e.target.value,
                              },
                            }
                          : node
                      )
                    );
                  }}
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  内容
                </label>
                <textarea
                  rows={4}
                  className="shadow-sm focus:ring-primary-500 focus:border-primary-500 block w-full sm:text-sm border border-gray-300 rounded-md"
                  value={selectedNode.data.content}
                  onChange={(e) => {
                    setNodes((nds) =>
                      nds.map((node) =>
                        node.id === selectedNode.id
                          ? {
                              ...node,
                              data: {
                                ...node.data,
                                content: e.target.value,
                              },
                            }
                          : node
                      )
                    );
                  }}
                />
              </div>
              
              <div className="pt-2">
                <h3 className="text-sm font-medium text-gray-700 mb-2">
                  连接
                </h3>
                <div className="space-y-2">
                  {edges
                    .filter(
                      (edge) =>
                        edge.source === selectedNode.id ||
                        edge.target === selectedNode.id
                    )
                    .map((edge) => {
                      const otherNodeId =
                        edge.source === selectedNode.id
                          ? edge.target
                          : edge.source;
                      const otherNode = nodes.find((n) => n.id === otherNodeId);
                      
                      if (!otherNode) return null;
                      
                      return (
                        <div
                          key={edge.id}
                          className="flex items-center p-2 bg-gray-50 rounded-md"
                        >
                          <div className="flex-shrink-0 h-8 w-8 rounded-full bg-gray-200 flex items-center justify-center">
                            {otherNode.data.type === 'main' && (
                              <LightBulbIcon className="h-4 w-4 text-yellow-500" />
                            )}
                            {otherNode.data.type === 'question' && (
                              <QuestionMarkCircleIcon className="h-4 w-4 text-blue-500" />
                            )}
                            {otherNode.data.type === 'idea' && (
                              <LightBulbIcon className="h-4 w-4 text-green-500" />
                            )}
                            {otherNode.data.type === 'note' && (
                              <InformationCircleIcon className="h-4 w-4 text-gray-500" />
                            )}
                            {otherNode.data.type === 'child' && (
                              <CheckCircleIcon className="h-4 w-4 text-purple-500" />
                            )}
                          </div>
                          <div className="ml-3">
                            <p className="text-sm font-medium text-gray-900 truncate max-w-[120px]">
                              {otherNode.data.label}
                            </p>
                            <p className="text-xs text-gray-500">
                              {edge.source === selectedNode.id ? '子节点' : '父节点'}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              <InformationCircleIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">
                未选择节点
              </h3>
              <p className="mt-1 text-sm text-gray-500">
                点击画布上的节点以查看和编辑其属性
              </p>
            </div>
          )}
        </div>

        {/* Graph canvas */}
        <div className="flex-1 bg-gray-50">
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onNodeClick={onNodeClick}
            onPaneClick={onPaneClick}
            nodeTypes={nodeTypes}
            fitView
            attributionPosition="bottom-left"
          >
            <Background />
            <Controls />
          </ReactFlow>
        </div>
      </div>
    </div>
  );
};

export default GraphEditorPage;
