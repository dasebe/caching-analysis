#pragma once

#include <iostream>
#include <memory>
#include <fstream>
#include <map>

class Parser;

class ParserFactory {
public:
    ParserFactory() {}
    virtual std::unique_ptr<Parser> create_unique() = 0;
};

class Parser {
protected:
    const std::string traceName;
    std::ifstream infile;
    int extraFields;
    ReqBatch batch;

    // helper function for factory pattern
    static std::map<std::string, ParserFactory *> &get_factory_instance() {
        static std::map<std::string, ParserFactory *> map_instance;
        return map_instance;
    }

public:
    Parser()
    {}
    virtual ~Parser() {
        infile.close();
    }
    virtual void setFile(std::string fname) = 0;
    void setExtraFields(int nextraFields) {
        extraFields = nextraFields;
    }

    virtual void closeFile(std::string fname) {
        infile.close();
    }

    virtual bool parseBatch(size_t parseReqs) = 0;
    ReqBatch & getBatch() {
        return batch;
    }

    // factory pattern
    static void registerType(std::string name, ParserFactory *factory) {
        get_factory_instance()[name] = factory;
    }
    static std::unique_ptr<Parser> create_unique(std::string name) {
        std::unique_ptr<Parser> Parser_instance;
        if(get_factory_instance().count(name) != 1) {
            std::cerr << "unkown format: " << name << "\n";
            return nullptr;
        }
        Parser_instance = get_factory_instance()[name]->create_unique();
        return Parser_instance;
    }

};
            

template<class T>
class Factory : public ParserFactory {
public:
    Factory(std::string name) { Parser::registerType(name, this); }
    std::unique_ptr<Parser> create_unique() {
        std::unique_ptr<Parser> newT(new T);
        return newT;
    }
};
