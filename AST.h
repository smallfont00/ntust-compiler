#pragma once
#include <algorithm>
#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <vector>
struct AST;
struct StatementAST;
struct TypedAST;
struct NamedAST;
struct ObjectAST;
struct FunctionAST;
struct ExprAST;
struct ValueAST;
struct VariableAST;
struct BinaryExprAST;
struct SingleExprAST;
struct InvokeAST;
struct AssignAST;
struct ReturnAST;
struct BlockAST;

struct Counter {
    int get();
    std::string get_str();
    int size();

   private:
    int counter = 0;
};

void Error(const char* format, ...);

struct AST {
    virtual std::string codegen() { return ""; };
    static std::string label(std::string = "WR");

   private:
    static Counter label_counter;
};

struct WriterAST : virtual AST {
    std::string text;
    WriterAST(std::string text) : text(text){};
    std::string codegen() { return text; };
};

struct StatementAST : virtual AST {
};

struct TypedAST : virtual AST {
    std::string type;
    TypedAST(std::string);
    TypedAST() = default;
    static bool type_check(std::vector<TypedAST*>, std::vector<std::string>);
    static bool same_type(std::vector<TypedAST*>);
};

struct NamedAST : virtual AST {
    std::string name;
    NamedAST(std::string);
};

struct SymbolTable {
    SymbolTable* parent = nullptr;
    Counter* counter = nullptr;
    std::map<std::string, NamedAST*> table;

    NamedAST* find(std::string);
    virtual void push(AST*) = 0;
};

struct ObjectAST : NamedAST, SymbolTable {
    std::vector<AST*> members;
    ObjectAST(std::string);
    std::string codegen() override;
    //NamedAST* find(std::string) override;
    void push(AST*) override;
};

struct FunctionAST : NamedAST, TypedAST {
    std::vector<VariableAST*> params;
    BlockAST* block;
    std::string identifier;
    std::function<void(std::string&, std::vector<ExprAST*>&)> loader;

    FunctionAST(std::string, std::string, std::vector<VariableAST*> = {});
    std::string invoke(std::vector<ExprAST*>);
    std::string codegen() override;
    std::string params_list();
};

struct ExprAST : virtual TypedAST, StatementAST {};

struct NullAST : ExprAST {};

struct ValueAST : ExprAST {
    std::string value;
    std::string load;
    bool is_from_const = true;
    ValueAST(std::string, std::string);
    explicit ValueAST(VariableAST*);
    std::string codegen() override;
};

struct VariableAST : NamedAST, TypedAST {
    ExprAST* init_value;
    std::string identifier;
    bool unchange = false;
    std::string load;
    std::string store;
    VariableAST(std::string, std::string);
    VariableAST(std::string, ExprAST*, bool = false);
    ValueAST* to_value();
};

struct BinaryExprAST : ExprAST {
    enum class OP { NUMBER = 1,
                    INTEGER,
                    COMPARE,
                    BOOLEAN };
    static std::map<std::string, OP> state;
    std::string op;
    std::string action_type;
    ExprAST* lhs;
    ExprAST* rhs;
    BinaryExprAST(std::string, ExprAST*, ExprAST*);
    std::pair<std::string, std::string> convert();
    std::string action();
    std::string codegen() override;
};

struct SingleExprAST : ExprAST {
    std::string op;
    std::string action_type;
    ExprAST* operand;
    SingleExprAST(std::string, ExprAST*);
    std::string codegen() override;
};

struct InvokeAST : ExprAST {
    std::vector<ExprAST*> args;
    FunctionAST* func;
    InvokeAST(FunctionAST*, std::vector<ExprAST*>);
    std::string codegen() override;
};

struct AssignAST : StatementAST {
    VariableAST* variable;
    ExprAST* expr;
    AssignAST(VariableAST*, ExprAST*);
    std::string codegen() override;
};

struct ReturnAST : StatementAST {
    ExprAST* expr;
    ReturnAST(ExprAST* = new NullAST);
    std::string codegen() override;
};

struct IfAST : StatementAST {
    ExprAST* expr;
    StatementAST* true_stmt;
    StatementAST* false_stmt;
    std::string codegen() override;
    IfAST(ExprAST*, StatementAST*, StatementAST*);
};

struct BlockAST : StatementAST, SymbolTable {
    std::vector<StatementAST*> stmts;
    BlockAST(SymbolTable*, std::vector<VariableAST*> = {});
    std::string codegen() override;
    void push(AST*) override;
};

struct WhileAST : StatementAST {
    ExprAST* expr;
    StatementAST* stmt;
    std::string codegen() override;
    WhileAST(ExprAST*, StatementAST*);
};