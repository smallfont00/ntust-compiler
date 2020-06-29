#include "AST.h"

#include <stdarg.h>

void Error(const char* format, ...) {
    va_list args;
    va_start(args, format);
    fprintf(stderr, "\n");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");
    va_end(args);
    exit(0);
}

std::string AST::label(std::string start) {
    return start + label_counter.get_str();
}

int Counter::get() { return counter++; }
std::string Counter::get_str() { return std::to_string(get()); }
int Counter::size() { return counter; }

Counter AST::label_counter;

std::map<std::string, BinaryExprAST::OP> BinaryExprAST::state = {
    {"+", OP::NUMBER},
    {"-", OP::NUMBER},
    {"*", OP::NUMBER},
    {"/", OP::NUMBER},
    {"%", OP::INTEGER},
    {"<", OP::COMPARE},
    {"<=", OP::COMPARE},
    {"==", OP::COMPARE},
    {"!=", OP::COMPARE},
    {">", OP::COMPARE},
    {">=", OP::COMPARE},
    {"&&", OP::BOOLEAN},
    {"||", OP::BOOLEAN}};

ObjectAST::ObjectAST(std::string name) : NamedAST(name) {
    // TODO: Print
    auto print = new FunctionAST("print", "void", {new VariableAST(" ", "any")});
    print->loader = [](std::string& text, std::vector<ExprAST*> args) {
        text = "getstatic java.io.PrintStream java.lang.System.out\n" + text;
        std::string vtype = args[0]->type;
        if (args[0]->type == "bool") vtype = "int";
        text += "invokevirtual void java.io.PrintStream.print(" + vtype + ")\n";
    };
    table[print->name] = print;

    // TODO: Println
    auto println = new FunctionAST("println", "void", {new VariableAST(" ", "any")});
    println->loader = [](std::string& text, std::vector<ExprAST*> args) {
        text = "getstatic java.io.PrintStream java.lang.System.out\n" + text;
        std::string vtype = args[0]->type;
        if (args[0]->type == "bool") vtype = "int";
        text += "invokevirtual void java.io.PrintStream.println(" + vtype + ")\n";
    };
    table[println->name] = println;

    // TODO: Read
};

std::string ObjectAST::codegen() {
    std::string text;
    text += "class " + name + "\n";
    text += "{\n";
    for (auto member : members) text += member->codegen();
    text += "}\n";
    return text;
};

void ObjectAST::push(AST* ast) {
    if (auto t1 = dynamic_cast<VariableAST*>(ast)) {
        if (t1->unchange) {
            if (!t1->init_value) Error("[Object <%s>] Const variable must be initialize\n", name.c_str());
            auto t2 = dynamic_cast<ValueAST*>(t1->init_value);
            if ((!t2) || (!t2->is_from_const)) Error("[Object <%s>] Static const variable must be initialize with simple value\n", name.c_str());
            t1->load = "ldc " + t2->value + "\n";
            table[t1->name] = t1;
            return;
        }

        table[t1->name] = t1;
        t1->identifier = name + "." + t1->name;

        std::string vtype = t1->type;
        if (t1->type == "bool") vtype = "int";

        t1->load = "getstatic " + vtype + " " + t1->identifier + "\n";
        t1->store = "putstatic " + vtype + " " + t1->identifier + "\n";

        std::string value;
        if (t1->init_value) {
            auto t2 = dynamic_cast<ValueAST*>(t1->init_value);
            if (!t2) Error("[Object <%s>] Static variable must be initialize with simple value\n", name.c_str());
            value = " = " + t2->value;
        }
        members.push_back(new WriterAST("field static " + vtype + " " + t1->name + value + "\n"));
        return;
    }
    if (auto t1 = dynamic_cast<FunctionAST*>(ast)) {
        table[t1->name] = t1;
        t1->identifier = name + "." + t1->name;

        if (t1->name == "main") {
            t1->params.push_back(new VariableAST(" ", "java.lang.String []"));
        }

        t1->loader = [t1](std::string& text, std::vector<ExprAST*> args) {
            std::string vtype = t1->type;
            if (t1->type == "bool") vtype = "int";
            text += "invokestatic " + vtype + " " + t1->identifier + t1->params_list() + "\n";
        };
        members.push_back(t1);
        return;
    }
    Error("[Object <%s>] received unknown member\n", name.c_str());
};

NamedAST::NamedAST(std::string name) : name(name){};

TypedAST::TypedAST(std::string type) : type(type){};

NamedAST* SymbolTable::find(std::string ast_name) {
    if (auto t1 = table.find(ast_name); t1 != table.end()) return t1->second;
    if (!parent) Error("[Symbol Table] <%s> not found\n", ast_name.c_str());
    if (auto t = parent->find(ast_name)) return t;
    Error("[Symbol Table] <%s> not found\n", ast_name.c_str());
};

bool TypedAST::type_check(std::vector<TypedAST*> operands, std::vector<std::string> types) {
    for (auto operand : operands) {
        bool ok = 0;
        for (auto type : types) {
            if (operand->type == type) {
                ok = true;
                break;
            }
        }
        if (!ok) return false;
    }
    return true;
};

bool TypedAST::same_type(std::vector<TypedAST*> operands) {
    for (int i = 0; i < operands.size() - 1; i++) {
        if (operands[i]->type != operands[i + 1]->type) return false;
    }
    return true;
};

VariableAST::VariableAST(std::string name, std::string type) : NamedAST(name), TypedAST(type){};

VariableAST::VariableAST(std::string name, ExprAST* val, bool unchange) : NamedAST(name), TypedAST(val->type), init_value(val), unchange(unchange){};

ValueAST* VariableAST::to_value() {
    auto result = new ValueAST(this);
    return result;
};

FunctionAST::FunctionAST(std::string name, std::string type, std::vector<VariableAST*> params) : NamedAST(name), TypedAST(type), params(params) {
    block = new BlockAST(nullptr, params);
};

std::string FunctionAST::params_list() {
    std::string text;
    text += "(";
    if (!params.empty()) {
        std::string vtype = params[0]->type;
        if (params[0]->type == "bool") vtype = "int";
        text += vtype;
        for (int i = 1; i < params.size(); i++) {
            if (params[i]->type == "bool") vtype = "int";
            text += "," + vtype;
        }
    }
    text += ")";
    return text;
};

std::string FunctionAST::codegen() {
    std::string text;
    std::string vtype = type;
    if (type == "bool") vtype = "int";
    text += "method public static " + vtype + " " + name + params_list() + "\n";
    text += "max_stack " + std::to_string(20 + (block->counter->size()) * 4) + "\n";
    text += "max_locals " + std::to_string(20 + (block->counter->size()) * 4) + "\n";
    text += "{\n";
    text += block->codegen();
    if (type == "int" || type == "bool") text += "iconst_0\nireturn\n";
    if (type == "float") text += "fconst_0\nfreturn\n";
    if (type == "void") text += "return\n";
    text += "}\n";
    return text;
};

std::string FunctionAST::invoke(std::vector<ExprAST*> exprs) {
    std::string text;
    for (auto expr : exprs) text += expr->codegen();
    loader(text, exprs);
    return text;
}

ValueAST::ValueAST(std::string type, std::string value) : TypedAST(type), value(value), load("ldc " + value + "\n"){};

ValueAST::ValueAST(VariableAST* var) : TypedAST(var->type), value(var->identifier), load(var->load), is_from_const(var->unchange){};

std::string ValueAST::codegen() {
    return load;
};

BinaryExprAST::BinaryExprAST(std::string op, ExprAST* lhs, ExprAST* rhs) : op(op), lhs(lhs), rhs(rhs) {
    auto op_type = state[op];
    switch (op_type) {
        case OP::NUMBER:
            if (!type_check({lhs, rhs}, {"float", "int"})) Error("[BinaryExpr] type error with <lhs:%s> <op:%s> <rhs:%s>\n", lhs->type.c_str(), op.c_str(), rhs->type.c_str());
            if (lhs->type == "float" || rhs->type == "float") {
                action_type = "f";
                type = "float";
                return;
            }
            action_type = "i";
            type = "int";
            return;
        case OP::INTEGER:
            if (!type_check({lhs, rhs}, {"int"})) Error("[BinaryExpr] type error with <lhs:%s> <op:%s> <rhs:%s>\n", lhs->type.c_str(), op.c_str(), rhs->type.c_str());
            action_type = "i";
            type = "int";
            return;
        case OP::COMPARE:
            if (!type_check({lhs, rhs}, {"float", "int"})) Error("[BinaryExpr] type error with <lhs:%s> <op:%s> <rhs:%s>\n", lhs->type.c_str(), op.c_str(), rhs->type.c_str());
            type = "bool";
            if (lhs->type == "float" || rhs->type == "float") {
                action_type = "f";
                return;
            }
            action_type = "i";
            return;
        case OP::BOOLEAN:
            if (!type_check({lhs, rhs}, {"bool"})) Error("[BinaryExpr] type error with <lhs:%s> <op:%s> <rhs:%s>\n", lhs->type.c_str(), op.c_str(), rhs->type.c_str());
            action_type = "i";
            type = "bool";
            return;
        default:
            Error("[BinaryExpr] no match\n");
    };
};

std::pair<std::string, std::string> BinaryExprAST::convert() {
    static std::map<std::string, int> order = {{"int", 0}, {"float", 1}};
    std::pair<std::string, std::string> result;
    int order_lhs = order[lhs->type];
    int order_rhs = order[rhs->type];
    if (order_lhs < order_rhs) {
        if (lhs->type == "int")
            return {"i2f\n", ""};
        Error("[Auto Convert] only support int to float");
    }
    if (order_lhs > order_rhs) {
        if (rhs->type == "int")
            return {"", "i2f\n"};
        Error("[Auto Convert] only support int to float");
    }
    return {"", ""};
};

std::string BinaryExprAST::action() {
    if (state[op] == OP::NUMBER) {
        if (op == "+") return action_type + "add\n";
        if (op == "-") return action_type + "sub\n";
        if (op == "*") return action_type + "mul\n";
        if (op == "/") return action_type + "div\n";
    }
    if (op == "%") {
        Error("[BinaryExpr] mod is not implemented\n");
    }
    if (state[op] == OP::COMPARE) {
        std::string text;
        if (action_type == "f")
            text += "fcmpg\n";
        else
            text += action_type + "sub\n";
        auto L1 = label();
        auto L2 = label();
        std::string if_action;
        if (op == "<") if_action += "iflt";
        if (op == "<=") if_action += "ifle";
        if (op == "==") if_action += "ifeq";
        if (op == "!=") if_action += "ifne";
        if (op == ">") if_action += "ifgt";
        if (op == ">=") if_action += "ifge";

        if_action += " " + L1 + "\n";
        text += if_action;
        text += "iconst_0\n";
        text += "goto " + L2 + "\n";

        //text += "goto " + L1 + "\n";
        text += L1 + ":\n";

        text += "iconst_1\n";

        //text += "goto " + L2 + "\n";
        text += L2 + ":\n";
        return text;
    }
    if (op == "&&") {
        return "iand\n";
    }
    if (op == "||") {
        return "ior\n";
    }
    Error("[BinaryExpr] no match for <op:%s>\n", op.c_str());
}

std::string BinaryExprAST::codegen() {
    std::string text;
    auto [convert_lhs, convert_rhs] = convert();
    text += lhs->codegen();
    text += convert_lhs;
    text += rhs->codegen();
    text += convert_rhs;
    text += action();
    return text;
};

SingleExprAST::SingleExprAST(std::string op, ExprAST* operand) : op(op), operand(operand) {
    if (op == "-" && type_check({operand}, {"int", "float"})) {
        type = operand->type;
        if (operand->type == "int") action_type = "i";
        if (operand->type == "float") action_type = "f";
        return;
    }
    if (op == "!" && type_check({operand}, {"bool", "int"})) {
        type = "bool";
        action_type = "i";
        return;
    }
    Error("[SingleExpr] no match for <op:%s>\n", op.c_str());
};

std::string SingleExprAST::codegen() {
    std::string text;
    text += operand->codegen();
    if (op == "-") return text + action_type + "neg\n";
    if (op == "!") return text + "iconst_1\n" + action_type + "xor\n";
    Error("[SingleExpr] no match for <op:%s>\n", op.c_str());
}

InvokeAST::InvokeAST(FunctionAST* func, std::vector<ExprAST*> args) : func(func), TypedAST(func->type), args(args) {
    if (func->params.size() != args.size()) Error("[Invoke] arguments number not match\n");
    for (int i = 0; i < args.size(); i++) {
        auto a = func->params[i];
        auto b = args[i];
        if (a->type == "any") continue;
        if (!same_type({a, b})) Error("[Invoke] parameters type not match. <%s:%s> and <arg:%s> not match\n", a->name.c_str(), a->type.c_str(), b->type.c_str());
    }
};

std::string InvokeAST::codegen() {
    std::string text;
    text += func->invoke(args);
    return text;
};

AssignAST::AssignAST(VariableAST* variable, ExprAST* expr) : variable(variable), expr(expr) {
    if (!TypedAST::same_type({variable, expr})) Error("[Assign] <%s:%s> not match with <rhs:%s>\n", variable->name.c_str(), variable->type.c_str(), expr->type.c_str());
};

std::string AssignAST::codegen() {
    std::string text;
    text += expr->codegen();
    text += variable->store;
    return text;
};

ReturnAST::ReturnAST(ExprAST* expr) : expr(expr){};

std::string ReturnAST::codegen() {
    if (dynamic_cast<NullAST*>(expr)) return "return\n";
    std::string text = expr->codegen();
    if (expr->type == "int" || expr->type == "bool") return text + "ireturn\n";
    if (expr->type == "float") return text + "freturn\n";
    Error("[Return] type not supported\n");
}

IfAST::IfAST(ExprAST* expr, StatementAST* tr, StatementAST* fa) : expr(expr), true_stmt(tr), false_stmt(fa) {
    if (!TypedAST::type_check({expr}, {"bool"})) Error("[IF] has to be boolean expression\n");
};

std::string IfAST::codegen() {
    std::string text;
    auto LF = label();
    auto LE = label();
    bool is_false_stmt_exist = !dynamic_cast<NullAST*>(false_stmt);

    text += expr->codegen();
    text += "ifeq " + LF + "\n";
    text += true_stmt->codegen();
    if (is_false_stmt_exist) text += "goto " + LE + "\n";

    //text += "goto " + LF + "\n";
    text += "nop\n";
    text += LF + ":\n";

    if (is_false_stmt_exist) {
        text += false_stmt->codegen();

        //text += "goto " + LE + "\n";
        text += "nop\n";
        text += LE + ":\n";
    }
    return text;
};

WhileAST::WhileAST(ExprAST* expr, StatementAST* stmt) : expr(expr), stmt(stmt) {
    if (!TypedAST::type_check({expr}, {"bool"})) Error("[WHILE] has to be boolean expression\n");
};

std::string WhileAST::codegen() {
    std::string text;
    auto LB = label();
    auto LE = label();

    //text += "goto " + LB + "\n";
    text += "nop\n";
    text += LB + ":\n";

    text += expr->codegen();
    text += "ifeq " + LE + "\n";
    text += stmt->codegen();
    text += "goto " + LB + "\n";

    //text += "goto " + LE + "\n";
    //text += "nop\n";
    text += LE + ":\n";

    return text;
};

BlockAST::BlockAST(SymbolTable* ptr, std::vector<VariableAST*> var_init) {
    if (ptr) {
        parent = ptr;
        counter = parent->counter;
    } else {
        counter = new Counter();
    }
    for (auto var : var_init) push(var);
}

std::string BlockAST::codegen() {
    std::string text;
    for (auto stmt : stmts) text += stmt->codegen();
    return text;
};

void BlockAST::push(AST* ast) {
    if (auto t1 = dynamic_cast<NamedAST*>(ast)) {
        if (table.count(t1->name)) Error("[Block] Re-define is not allow\n");
    }
    if (auto t1 = dynamic_cast<StatementAST*>(ast)) {
        if (auto t1 = dynamic_cast<AssignAST*>(ast)) {
            if (t1->variable->unchange) Error("[Block] Constant cannot be change\n");
        }
        stmts.push_back(t1);
        return;
    }
    if (auto t1 = dynamic_cast<VariableAST*>(ast)) {
        t1->identifier = counter->get_str();
        std::string action_type = "i";
        if (t1->type == "float") action_type = "f";

        if (t1->unchange) {
            if (!t1->init_value) Error("[Block] Const variable must be initialize\n");

            if (auto t2 = dynamic_cast<ValueAST*>(t1->init_value)) {
                t1->load = "ldc " + t2->value + "\n";
                table[t1->name] = t1;
                return;
            } else {
                t1->load = action_type + "load " + t1->identifier + "\n";
                t1->store = action_type + "store " + t1->identifier + "\n";
                table[t1->name] = t1;

                t1->unchange = false;
                push(new AssignAST(t1, t1->init_value));
                t1->unchange = true;
                return;
            }
        }

        t1->load = action_type + "load " + t1->identifier + "\n";
        t1->store = action_type + "store " + t1->identifier + "\n";
        table[t1->name] = t1;
        if (t1->init_value) push(new AssignAST(t1, t1->init_value));

        return;
    }
    if (auto t1 = dynamic_cast<AssignAST*>(ast)) {
        if (t1->variable->unchange) Error("[Block] Constant cannot be change\n");
    }
    Error("[Block] received unknown member\n");
};