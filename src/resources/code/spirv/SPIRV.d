module resources.code.spirv.SPIRV;

import resources.all;

import std.stdio;
import std.file : read;
import std.bitmanip;

import resources.code.spirv.spirv_types;

/**
 * A class for reading and parsing SPIR-V binary files.
 *
 * Supports Up to and including version 1.6 
 *
 * https://github.com/KhronosGroup/SPIRV-Headers/blob/main/include/spirv/unified1/spirv.h
 * https://registry.khronos.org/SPIR-V/specs/unified1/SPIRV.html#PhysicalLayout
 */
final class SPIRV {
public:    
    static SPIRV read(string filename) { 
        auto spirv = new SPIRV();
        spirv.doRead(filename);
        return spirv;
    }
private:
    ByteReader reader;

    struct LiteralString {
        string value;
        uint wordCount;
    }

    void doRead(string filename) { 
        reader = new FileByteReader(filename);
        scope(exit) reader.close();

        readMagic();

        uint version_ = reader.read!uint;
        chat("version: %s.%s", (version_>>>16)&0xff, (version_>>>8)&0xff);

        uint generator = reader.read!uint;
        chat("generator: %08x", generator);

        uint bound = reader.read!uint;
        chat("bound: %s", bound);

        uint schema = reader.read!uint;
        chat("schema: %s", schema);

        readInstructions();
    }
    void readMagic() {
        uint magic = reader.read!uint;
        chat("magic: %x", magic);
        if(magic == 0x03022307) {
            throw new Exception("Big endian SPIR-V not supported yet");
        } else if(magic != 0x07230203) {
            throw new Exception("Invalid SPIR-V magic number: %x".format(magic));
        }
    }
    /**
     * Note: This is not an exhaustive list of instructions. Add more as necessary.
     * 
     * At the moment all we do is log
     */
    void readInstructions() {
        chat("Reading Instructions:");
        while(!reader.eof()) {
            uint i = reader.read!uint;
            int wordCount = (i >>> 16) & 0xffff;
            uint opcode = i & 0xffff;
            //chat("Instruction: op: %s, Word Count: %s", opcode.as!SpvOp, wordCount);

            switch(opcode) with(SpvOp) {
                case AccessChain: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint base = reader.read!uint;
                    uint[] indices = reader.readArray!uint(wordCount-4);
                    
                    chat("  @%s = AccessChain: resultType:@%s, base:@%s, indices:%s", 
                        resultId, resultType, base, indices.map!(it=>"@%s".format(it)));
                    break;
                }
                case Any: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint vector = reader.read!uint;
                    chat("  @%s = Any: resultType:@%s, vetctor:@%s", resultId, resultType, vector);
                    break;
                }
                case Bitcast: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand = reader.read!uint;
                    chat("  @%s = Bitcast: resultType:@%s, operand:@%s", resultId, resultType, operand);
                    break;
                }
                case BitCount: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand = reader.read!uint;
                    chat("  @%s = BitCount: resultType:@%s, operand:@%s", resultId, resultType, operand);
                    break;
                }
                case BitFieldUExtract: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint base = reader.read!uint;
                    uint offset = reader.read!uint;
                    uint count = reader.read!uint;
                    chat("  @%s = BitFieldUExtract: resultType:@%s, base:@%s, offset:@%s, count:@%s", resultId, resultType, base, offset, count);
                    break;
                }
                case BitwiseAnd: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = BitwiseAnd: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case BitwiseOr: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = BitwiseOr: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case Branch: {
                    uint label = reader.read!uint;
                    chat("  Branch: label:@%s", label);
                    break;
                }
                case BranchConditional: {
                    uint condition = reader.read!uint;
                    uint trueLabel = reader.read!uint;
                    uint falseLabel = reader.read!uint;
                    uint[] weights = reader.readArray!uint(wordCount-4);
                    chat("  BranchConditional: condition:@%s, trueLabel:@%s, falseLabel:@%s, weights:%s", condition, trueLabel, falseLabel, weights);
                    break;
                }
                case Capability: {
                    SpvCapability cap = reader.read!uint.as!SpvCapability;
                    chat("  Capability: %s", cap);
                    break;   
                }
                case CompositeConstruct: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint[] constituents = reader.readArray!uint(wordCount-3);
                    chat("  @%s = CompositeConstruct: resultType:@%s, constituents:%s", 
                        resultId, resultType, constituents.map!(it=>"@%s".format(it)));
                    break;
                }
                case CompositeExtract: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint composite = reader.read!uint;
                    uint[] indices = reader.readArray!uint(wordCount-4);
                    chat("  @%s = CompositeExtract: resultType:@%s, composite:@%s, indices:%s", 
                        resultId, resultType, composite, indices);
                    break;
                }
                case CompositeInsert: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint object = reader.read!uint;
                    uint composite = reader.read!uint;
                    uint[] indices = reader.readArray!uint(wordCount-5);
                    chat("  @%s = CompositeInsert: resultType:@%s, object:@%s, composite:@%s, indices:%s", 
                        resultId, resultType, object, composite, indices);
                    break;
                }
                case Constant: {
                    uint type = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    if(wordCount > 4) {
                        todo("handle 64-bit constants");
                    }
                    chat("  @%s = Constant: type:@%s, value:%s", resultId, type, value);
                    break;
                }    
                case ConstantComposite: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint[] constituents = reader.readArray!uint(wordCount-3);
                    chat("  @%s = ConstantComposite: resultType:@%s, constituents:%s", 
                        resultId, resultType, constituents.map!(it=>"@%s".format(it)));
                    break;
                }
                case ConstantFalse: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    chat("  @%s = ConstantFalse: resultType:@%s", resultId, resultType);
                    break;
                }
                case ConstantNull: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    chat("  @%s = ConstantNull: resultType:@%s", resultId, resultType);
                    break;
                }
                case ConstantTrue: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    chat("  @%s = ConstantTrue: resultType:@%s", resultId, resultType);
                    break;
                }
                case ConvertFToS: { // convert float to signed int
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    chat("  @%s = ConvertFToS: resultType:@%s, value:@%s", resultId, resultType, value);
                    break;
                }
                case ConvertFToU: { // convert float to unsigned int with round toward 0.0
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    chat("  @%s = ConvertFToU: resultType:@%s, value:@%s", resultId, resultType, value);
                    break;
                }
                case ConvertSToF: { // convert signed int to float
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    chat("  @%s = ConvertSToF: resultType:@%s, value:@%s", resultId, resultType, value);
                    break;
                }
                case ConvertUToF: { // convert unsigned int to float
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    chat("  @%s = ConvertUToF: resultType:@%s, value:@%s", resultId, resultType, value);
                    break;
                }
                case Decorate: {
                    uint targetId = reader.read!uint;
                    SpvDecoration decoration = reader.read!uint.as!SpvDecoration;
                    uint[] params = reader.readArray!uint(wordCount-3);
                    chat("  Decorate: @%s = %s %s", targetId, decoration, params);
                    break;
                }    
                case Dot: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint vector1 = reader.read!uint;
                    uint vector2 = reader.read!uint;
                    chat("  @%s = Dot: resultType:@%s, vector1:@%s, vector2:@%s", resultId, resultType, vector1, vector2);
                    break;
                }
                case EmitVertex: {
                    chat("  EmitVertex");
                    break;
                }
                case EndPrimitive: {
                    chat("  EndPrimitive");
                    break;
                }
                case EntryPoint: {
                    SpvExecutionModel exec = reader.read!uint.as!SpvExecutionModel;
                    uint entryPoint = reader.read!uint;
                    wordCount -= 3;
                    auto name = readLiteralString();
                    wordCount -= name.wordCount;
                    uint[] params = reader.readArray!uint(wordCount);
                    chat("  EntryPoint: %s, functionId:%s, '%s' params = %s", exec, entryPoint, name.value, params);
                    break;
                }
                case ExecutionMode: {   
                    uint entryPoint = reader.read!uint;
                    SpvExecutionMode mode = reader.read!uint.as!SpvExecutionMode;
                    wordCount -= 3;
                    chat("  ExecutionMode: entryPointId:%s, mode:%s", entryPoint, mode);
                    foreach(n; 0..wordCount) {
                        uint w = reader.read!uint;
                        chat("   -- param: %s", w);
                    }
                    break;
                }
                case ExtInst: { // Execute an instruction in an imported set of extended instructions
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint set = reader.read!uint;
                    uint instruction = reader.read!uint;
                    uint[] operands = reader.readArray!uint(wordCount-5);
                    chat("  @%s = ExtInst: resultType:@%s, set:@%s, instruction:%s, operands:%s", 
                        resultId, resultType, set, instruction, operands.map!(it=>"@%s".format(it)));
                    break;
                }
                case ExtInstImport: {
                    uint resultId = reader.read!uint;
                    LiteralString name = readLiteralString();
                    chat("  @%s = ExtInstImport: name:%s", resultId, name.value);
                    break;
                }
                case FAdd: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FAdd: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FDiv: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FDiv: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FMod: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FMod: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FMul: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FMul: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FNegate: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand = reader.read!uint;
                    chat("  @%s = FNegate: resultType:@%s, operand:@%s", resultId, resultType, operand);
                    break;
                }
                case FOrdEqual: { // Floating-point comparison if operands are ordered and Operand 1 is equal to Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FOrdEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FOrdGreaterThan: { // Floating-point comparison if operands are ordered and Operand 1 is greater than Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FOrdGreaterThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FOrdGreaterThanEqual: { // Floating-point comparison if operands are ordered and Operand 1 is greater than or equal to Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FOrdGreaterThanEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FOrdLessThan: { // Floating-point comparison if operands are ordered and Operand 1 is less than Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;    
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FOrdLessThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FOrdLessThanEqual: { // Floating-point comparison if operands are ordered and Operand 1 is less than or equal to Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FOrdLessThanEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case FSub: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FSub: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case Function: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint control = reader.read!uint;
                    uint functionType = reader.read!uint;
                    chat("  @%s = Function: control:%s, resultType:@%s, functionType:@%s", resultId, functionControlToString(control), resultType, functionType);
                    break;
                }
                case FunctionCall: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint function_ = reader.read!uint;
                    uint[] args = reader.readArray!uint(wordCount-4);
                    chat("  @%s = FunctionCall: resultType:@%s, function:@%s, args:%s", resultId, resultType, function_, args.map!(it=>"@%s".format(it)));
                    break;
                }
                case FunctionEnd: {
                    chat("  FunctionEnd");
                    break;
                }
                case FunctionParameter: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    chat("  @%s = FunctionParameter: resultType:@%s", resultId, resultType);
                    break;
                }
                case FUnordEqual: { // Floating-point comparison if operands are unordered and Operand 1 is equal to Operand 2
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = FUnordEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case IAdd: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = IAdd: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case IEqual: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = IEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case ImageQuerySize: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint image = reader.read!uint;
                    chat("  @%s = ImageQuerySize: resultType:@%s, image:@%s", resultId, resultType, image);
                    break;
                }
                case ImageSampleExplicitLod: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint sampledImage = reader.read!uint;
                    uint coordinate = reader.read!uint;
                    uint imageOperands = reader.read!uint;
                    uint[] ops = reader.readArray!uint(wordCount-6);

                    chat("  @%s = ImageSampleExplicitLod: resultType:@%s, sampledImage:@%s, coordinate:@%s, operands:%s %s", 
                        resultId, resultType, sampledImage, coordinate, 
                        imageOperandsToString(imageOperands), ops);
                    break;
                }
                case ImageSampleImplicitLod: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint sampledImage = reader.read!uint;
                    uint coordinate = reader.read!uint;
                    uint imageOperands;
                    uint[] ops;

                    if(wordCount > 5) {
                        imageOperands = reader.read!uint;
                        ops = reader.readArray!uint(wordCount-6);
                    }

                    chat("  @%s = ImageSampleImplicitLod: resultType:@%s, sampledImage:@%s, coordinate:@%s, operands:%s %s", 
                        resultId, resultType, sampledImage, coordinate, 
                        imageOperandsToString(imageOperands), ops);
                    break;
                }
                case ImageWrite: {
                    uint image = reader.read!uint;
                    uint coordinate = reader.read!uint;
                    uint texel = reader.read!uint;
                    uint imageOperands;
                    uint[] ops;
                    if(wordCount > 4) {
                        imageOperands = reader.read!uint;
                        ops = reader.readArray!uint(wordCount-5);
                    }

                    chat("  ImageWrite: image:@%s, coordinate:@%s, texel:@%s, operands:%s %s", 
                        image, coordinate, texel, imageOperandsToString(imageOperands), ops);
                    break;
                }

                case IMul: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = IMul: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case INotEqual: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = INotEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case ISub: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = ISub: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case Kill: {
                    chat("  Kill");
                    break;
                }
                case Label: {
                    uint resultId = reader.read!uint;
                    chat("  @%s = Label", resultId);
                    break;
                }
                case Load: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint pointer = reader.read!uint;
                    uint memoryAccess;
                    if(wordCount > 4) {
                       memoryAccess = reader.read!uint;
                    }
                    chat("  @%s = Load: resultType:@%s, pointer:@%s, memoryAccess:%s", 
                        resultId, resultType, pointer, .toString!SpvMemoryAccess(memoryAccess, null, null));
                    break;
                }
                case LogicalAnd: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = LogicalAnd: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case LogicalNot: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand = reader.read!uint;
                    chat("  @%s = LogicalNot: resultType:@%s, operand:@%s", resultId, resultType, operand);
                    break;
                }
                case LogicalOr: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = LogicalOr: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case LoopMerge: {
                    uint mergeBlock = reader.read!uint;
                    uint continueTarget = reader.read!uint;
                    SpvLoopControl control = reader.read!uint.as!SpvLoopControl;
                    uint[] params = reader.readArray!uint(wordCount-4);
                    chat("  LoopMerge: mergeBlock:@%s, continueTarget:@%s, control:%s, params:%s", 
                        mergeBlock, continueTarget, .toArray!SpvLoopControl(control), params);
                    break;
                }
                case MatrixTimesMatrix: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint leftMatrix = reader.read!uint;
                    uint rightMatrix = reader.read!uint;
                    chat("  @%s = MatrixTimesMatrix: resultType:@%s, leftMatrix:@%s, rightMatrix:@%s", 
                        resultId, resultType, leftMatrix, rightMatrix);
                    break;
                }
                case MatrixTimesVector: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint matrix = reader.read!uint;
                    uint vector = reader.read!uint;
                    chat("  @%s = MatrixTimesVector: resultType:@%s, matrix:@%s, vector:@%s", 
                        resultId, resultType, matrix, vector);
                    break;
                }
                case MemberDecorate: {
                    uint structId = reader.read!uint;
                    uint index = reader.read!uint;
                    SpvDecoration decoration = reader.read!uint.as!SpvDecoration;
                    uint[] params = reader.readArray!uint(wordCount-4);
                    chat("  MemberDecorate: structId:%s, index:%s, %s %s", structId, index, decoration, params);
                    break;
                }
                case MemberName: { // struct member name
                    uint structId = reader.read!uint;
                    uint member = reader.read!uint;
                    auto name = readLiteralString();
                    chat("  MemberName: structId:%s, index:%s, name:'%s'", structId, member, name.value);
                    break;
                }
                case MemoryModel: 
                    SpvAddressingModel addr = reader.read!uint.as!SpvAddressingModel;
                    SpvMemoryModel mem = reader.read!uint.as!SpvMemoryModel;
                    chat("  MemoryModel: %s, %s", addr, mem);
                    break;
                case Name: {
                    uint targetId = reader.read!uint;
                    auto name = readLiteralString();
                    chat("  Name: @%s = '%s'", targetId, name.value);
                    break;
                }    
                case Phi: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint[] incomingValues = reader.readArray!uint(wordCount-3);
                    chat("  @%s = Phi: resultType:@%s, incomingValues:%s", resultId, resultType, incomingValues.map!(a => format("@%s", a)));
                    break;
                }
                case Return: {
                    chat("  Return");
                    break;
                }
                case ReturnValue: {
                    uint value = reader.read!uint;
                    chat("  ReturnValue: value:@%s", value);
                    break;
                }
                case Select: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint condition = reader.read!uint;
                    uint objectTrue = reader.read!uint;
                    uint objectFalse = reader.read!uint;
                    chat("  @%s = Select: resultType:@%s, condition:@%s, objectTrue:@%s, objectFalse:@%s", 
                        resultId, resultType, condition, objectTrue, objectFalse);
                    break;
                }
                case SelectionMerge: {
                    uint mergeBlock = reader.read!uint;
                    SpvSelectionControl control = reader.read!uint.as!SpvSelectionControl;
                    chat("  SelectionMerge: mergeBlock:@%s, control:%s", mergeBlock, control);
                    break;
                }
                case SGreaterThan: { // signed >
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = SGreaterThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case SGreaterThanEqual: { // signed >=
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = SGreaterThanEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case ShiftLeftLogical: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint base = reader.read!uint;
                    uint shift = reader.read!uint;
                    chat("  @%s = ShiftLeftLogical: resultType:@%s, base:@%s, shift:@%s", resultId, resultType, base, shift);
                    break;
                }
                case ShiftRightArithmetic: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint base = reader.read!uint;
                    uint shift = reader.read!uint;
                    chat("  @%s = ShiftRightArithmetic: resultType:@%s, base:@%s, shift:@%s", resultId, resultType, base, shift);
                    break;
                }
                case ShiftRightLogical: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint base = reader.read!uint;
                    uint shift = reader.read!uint;
                    chat("  @%s = ShiftRightLogical: resultType:@%s, base:@%s, shift:@%s", resultId, resultType, base, shift);
                    break;
                }
                case SLessThan: { // signed <
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = SLessThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case SLessThanEqual: { // signed <=
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = SLessThanEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case Source: {
                    SpvSourceLanguage lang = reader.read!uint.as!SpvSourceLanguage;
                    uint version_ = reader.read!uint;
                    chat("  Source: lang:%s, version:%s", lang, version_);
                    if(wordCount > 3) {
                        uint fileId = reader.read!uint;
                        chat("   -- fileId: %s", fileId);
                    }
                    if(wordCount > 4) {
                        auto source = readLiteralString();
                        chat("   -- source: %s bytes", source.value.length);
                    }
                    break;
                }
                case SourceExtension: {
                    LiteralString name = readLiteralString();
                    chat("  SourceExtension: name:%s", name.value);
                    break;
                }
                case SpecConstant: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint value = reader.read!uint;
                    if(wordCount > 4) {
                        todo("handle 64-bit constants");
                    }
                    chat("  @%s = SpecConstant: resultType:@%s, value:%s", resultId, resultType, value);
                    break;
                }
                case SpecConstantComposite: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint[] constituents = reader.readArray!uint(wordCount-3);
                    chat("  @%s = SpecConstantComposite: resultType:@%s, constituents:%s", 
                        resultId, resultType, constituents.map!(it=>"@%s".format(it)));
                    break;
                }
                case Store: {
                    uint pointer = reader.read!uint;
                    uint object = reader.read!uint;
                    uint memoryAccess;
                    if(wordCount > 3) {
                       memoryAccess = reader.read!uint;
                    }
                    chat("  Store: pointer:@%s, object:@%s, memoryAccess:%s", 
                        pointer, object, .toString!SpvMemoryAccess(memoryAccess, null, null));
                    break;
                }
                case Switch: {
                    uint selector = reader.read!uint;
                    uint defaultTarget = reader.read!uint;
                    uint[] targets = reader.readArray!uint(wordCount-3);
                    chat("  Switch: selector:@%s, defaultTarget:@%s, targets:%s", selector, defaultTarget, targets);
                    break;
                }
                case TypeArray: {
                    uint resultId = reader.read!uint;
                    uint elementType = reader.read!uint;
                    uint length = reader.read!uint;
                    chat("  @%s = TypeArray: elementType:@%s, length:@%s", resultId, elementType, length);
                    break;
                }
                case TypeBool: {
                    uint resultId = reader.read!uint;
                    chat("  @%s = TypeBool", resultId);
                    break;
                }
                case TypeFloat: {
                    uint resultId = reader.read!uint;
                    uint width = reader.read!uint;
                    if(wordCount > 3) {
                        todo("handle FP encoding");
                    }
                    chat("  @%s = TypeFloat: width:%s", resultId, width);
                    break;
                }
                case TypeFunction: {
                    uint resultId = reader.read!uint;
                    uint returnType = reader.read!uint;
                    uint[] paramTypes = reader.readArray!uint(wordCount-3);
                    chat("  @%s = TypeFunction: returnType:@%s, paramTypes = %s", resultId, returnType, paramTypes);
                    break;
                }
                case TypeImage: {
                    uint resultId = reader.read!uint;
                    uint sampledType = reader.read!uint;
                    SpvDim dim = reader.read!uint.as!SpvDim;
                    uint depth = reader.read!uint;
                    uint arrayed = reader.read!uint;
                    uint ms = reader.read!uint;
                    uint sampled = reader.read!uint;
                    SpvImageFormat format = reader.read!uint.as!SpvImageFormat;
                    SpvAccessQualifier access = SpvAccessQualifier.Max;
                    if(wordCount > 9) {
                        access = reader.read!uint.as!SpvAccessQualifier;
                    }
                    chat("  @%s = TypeImage: sampledType:@%s, dim:%s, depth:%s, arrayed:%s, ms:%s, sampled:%s, format:%s, access:%s", 
                        resultId, sampledType, dim, depthToString(depth), arrayedToString(arrayed), 
                        msToString(ms), sampledToString(sampled), format, accessToString(access));
                    break;
                }
                case TypeInt: {
                    uint resultId = reader.read!uint;
                    uint width = reader.read!uint;
                    uint signedness = reader.read!uint;
                    chat("  @%s = TypeInt: %s bits, %s", resultId, width, signednessToString(signedness));
                    break;
                }
                case TypeMatrix: {
                    uint resultId = reader.read!uint;
                    uint columnType = reader.read!uint;
                    uint columnCount = reader.read!uint;
                    chat("  @%s = TypeMatrix: columnType:@%s, columnCount:%s", resultId, columnType, columnCount);
                    break;
                }
                case TypePointer: {
                    uint resultId = reader.read!uint;
                    SpvStorageClass storageClass = reader.read!uint.as!SpvStorageClass;
                    uint type = reader.read!uint;
                    chat("  @%s = TypePointer: storageClass:%s, type:@%s", resultId, storageClass, type);
                    break;
                }
                case TypeRuntimeArray: {
                    uint resultId = reader.read!uint;
                    uint elementType = reader.read!uint;
                    chat("  @%s = TypeRuntimeArray: elementType:@%s", resultId, elementType);
                    break;
                }
                case TypeSampledImage: {
                    uint resultId = reader.read!uint;
                    uint imageType = reader.read!uint;
                    chat("  @%s = TypeSampledImage: imageType:@%s", resultId, imageType);
                    break;
                }
                case TypeStruct: {
                    uint resultId = reader.read!uint;
                    uint[] memberTypes = reader.readArray!uint(wordCount-2);
                    chat("  @%s = TypeStruct: memberTypes = %s", resultId, memberTypes);
                    break;
                }
                case TypeVector: {
                    uint resultId = reader.read!uint;
                    uint componentType = reader.read!uint;
                    uint componentCount = reader.read!uint;
                    chat("  @%s = TypeVector: type:@%s, count:%s", resultId, componentType, componentCount);
                    break;
                }
                case TypeVoid: {
                    uint resultId = reader.read!uint;
                    chat("  @%s = TypeVoid", resultId);
                    break;
                }
                case UDiv: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = UDiv: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case UGreaterThan: { // unsigned >
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = UGreaterThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case UGreaterThanEqual: { // unsigned >=
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = UGreaterThanEqual: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case ULessThan: { // unsigned <
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = ULessThan: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case UMod: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint operand1 = reader.read!uint;
                    uint operand2 = reader.read!uint;
                    chat("  @%s = UMod: resultType:@%s, operand1:@%s, operand2:@%s", resultId, resultType, operand1, operand2);
                    break;
                }
                case Undef: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    chat("  @%s = Undef: resultType:@%s", resultId, resultType);
                    break;
                }
                case Variable: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    SpvStorageClass storageClass = reader.read!uint.as!SpvStorageClass;
                    uint initializer = -1;
                    if(wordCount > 4) {
                        initializer = reader.read!uint;
                    }
                    chat("  @%s = Variable: storageClass:%s, resultType:@%s, initialiser:%s", 
                        resultId, storageClass, resultType, 
                        initializer == -1 ? "none" : "@%s".format(initializer));
                    break;
                }
                case VectorShuffle: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint vector1 = reader.read!uint;
                    uint vector2 = reader.read!uint;
                    uint[] components = reader.readArray!uint(wordCount-5);
                    chat("  @%s = VectorShuffle: resultType:@%s, vector1:@%s, vector2:@%s, components = %s", resultId, resultType, vector1, vector2, components);
                    break;
                }
                case VectorTimesMatrix: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint vector = reader.read!uint;
                    uint matrix = reader.read!uint;
                    chat("  @%s = VectorTimesMatrix: resultType:@%s, vector:@%s, matrix:@%s", resultId, resultType, vector, matrix);
                    break;
                }
                case VectorTimesScalar: {
                    uint resultType = reader.read!uint;
                    uint resultId = reader.read!uint;
                    uint vector = reader.read!uint;
                    uint scalar = reader.read!uint;
                    chat("  @%s = VectorTimesScalar: resultType:@%s, vector:@%s, scalar:@%s", resultId, resultType, vector, scalar);
                    break;
                }
                
                
                
                
                
                
                
                
                

                default: {
                    chat(" !!! Unhandled opcode: %s (%s words)", opcode.as!SpvOp, wordCount);
                    foreach(n; 0..wordCount-1) {
                        uint w = reader.read!uint;
                        chat("   -- Word: %s", w);
                    }
                    chat("Exiting...");
                    return;
                } 
            }
        }
    }
    LiteralString readLiteralString() {
        LiteralString ln;
        char[] chars;
        while(!reader.eof()) {
            uint w = reader.read!uint;
            ln.wordCount++;

            foreach(i; 0..4) {
                char ch = w & 0xff;
                if(ch == 0) {
                    ln.value = chars.to!string;
                    return ln;
                }
                chars ~= ch;
                w >>>= 8;
            }
        }
        throwIf(true, "Unexpected EOF while reading literal name");
        assert(false);
    }
    string signednessToString(uint signedness) {
        return signedness == 0 ? "unsigned" : "signed";
    }
    string depthToString(uint depth) {
        return depth == 0 ? "not depth" : depth == 1 ? "depth" : "unknown";
    }
    string arrayedToString(uint b) {
        return b == 0 ? "non-arrayed" : "arrayed";
    }
    string msToString(uint b) {
        return b == 0 ? "single-sampled" : "multisampled";
    }
    string sampledToString(uint b) {
        return b == 0 ? "unknown" : b == 1 ? "read-only" : "read-write";
    }
    string accessToString(SpvAccessQualifier access) {
        return access == SpvAccessQualifier.Max ? "unknwown" : "%s".format(access);
    }
    string functionControlToString(uint control) {
        return .toString!SpvFunctionControl(control, null, null);
    }
    string imageOperandsToString(uint operands) {
        auto array = toArray!SpvImageOperands(operands);
        if(array.length == 0) return "none";
        return "%s".format(array);
    }
}
