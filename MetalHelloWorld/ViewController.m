//
//  ViewController.m
//  MetalHelloWorld
//
//  Created by Nathaniel R. Lewis on 8/4/15.
//  Copyright (c) 2015 HoodooNet. All rights reserved.
//

#import "ViewController.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) CAMetalLayer* metalLayer;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) CADisplayLink* timer;

@end

@implementation ViewController
{
    dispatch_semaphore_t  m_InflightSemaphore;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    m_InflightSemaphore = dispatch_semaphore_create(3);
    
    // Do any additional setup after loading the view, typically from a nib.
    self.device = MTLCreateSystemDefaultDevice();
    
    self.metalLayer = [CAMetalLayer new];
    self.metalLayer.device = self.device;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = true;
    self.metalLayer.frame = self.view.layer.frame;
    
    [self.view.layer addSublayer:self.metalLayer];
    
    float vertexData[] =
    {
        0.0, 1.0, 0.0,
        1.0, 0.0, 0.0, 1.0,
        
        -1.0, -1.0, 0.0,
        0.0, 1.0, 0.0, 1.0,
        
        1.0, -1.0, 0.0,
        0.0, 0.0, 1.0, 1.0,
    };
    self.vertexBuffer = [self.device newBufferWithBytes:&vertexData[0] length:sizeof(vertexData) options:0];
    
    id<MTLLibrary> defaultLibrary = [self.device newDefaultLibrary];
    id<MTLFunction> fragmentProgram = [defaultLibrary newFunctionWithName:@"basic_fragment"];
    id<MTLFunction> vertexProgram = [defaultLibrary newFunctionWithName:@"basic_vertex"];
    
    MTLRenderPipelineDescriptor *descriptor = [MTLRenderPipelineDescriptor new];
    descriptor.vertexFunction = vertexProgram;
    descriptor.fragmentFunction = fragmentProgram;
    descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *pipelineError = nil;
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:descriptor error:&pipelineError];
    if(!self.pipelineState)
    {
        NSLog(@"Failed to create pipeline state with error: %@", pipelineError);
        return;
    }
    
    self.commandQueue = [self.device newCommandQueue];
    
    self.timer = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(gameloop)];
    self.timer.frameInterval = 1;
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.metalLayer.frame = self.view.layer.frame;
}

- (void)render
{
    dispatch_semaphore_wait(m_InflightSemaphore, DISPATCH_TIME_FOREVER);
    
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *descriptor = [MTLRenderPassDescriptor new];
    descriptor.colorAttachments[0].texture = drawable.texture;
    descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 104.0/255.0, 5.0/255.0, 1.0);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:descriptor];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3 instanceCount:1];
    [renderEncoder endEncoding];
    
    // Dispatch the command buffer
    __block dispatch_semaphore_t dispatchSemaphore = m_InflightSemaphore;
    
    [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> cmdb)
    {
        dispatch_semaphore_signal(dispatchSemaphore);
    }];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

- (void)gameloop
{
    @autoreleasepool
    {
        [self render];
    }
}

@end
